import time
from log_factory import get_logger
import os
import csv
from pathlib import Path
from comms_proxy import Comms_Proxy

# Imports for the watchdog that monitors dictionary file changes
import threading
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import hashlib

class _DictChangeHandler(FileSystemEventHandler):
    """
    Reload the dictionaries every time one changes, but when one changes several 
    change. I only want to run the reload once per change event so wait 1 second 
    before launching that change to allow time for more changes to roll in. 
    Any modification to a dictionary file restarts a
    1-second timer.  When the timer finally fires, the engine reloads the
    whole bundle exactly once.
    """

    DEBOUNCE_SECONDS = 1.0          # <-- change this if you want a different delay

    def __init__(self, engine: "Expansion_Engine"):
        self.engine = engine
        # Cache of the last known hash per file – prevents reloads on
        # timestamp‑only touches (optional but cheap).
        self._hash_cache: dict[Path, str] = {}
        # The timer that will actually trigger the reload.
        self._timer: threading.Timer | None = None
        # Protect the timer from race conditions (handler may be called
        # from multiple threads on some platforms).
        self._lock = threading.Lock()
        super().__init__()

    # ------------------------------------------------------------------
    #  Helper: compute a short SHA‑256 digest of a file to detect content changes
    # ------------------------------------------------------------------
    @staticmethod
    def _file_hash(path: Path) -> str | None:
        try:
            h = hashlib.sha256()
            with path.open("rb") as f:
                for chunk in iter(lambda: f.read(8192), b""):
                    h.update(chunk)
            return h.hexdigest()
        except (OSError, PermissionError):
            return None

    # ------------------------------------------------------------------
    #  Core event – we only care about modifications (writes)
    # ------------------------------------------------------------------
    def on_modified(self, event):
        if event.is_directory:
            return

        path = Path(event.src_path).resolve()
        new_hash = self._file_hash(path)

        # If we cannot read the file (e.g. still being written), just ignore.
        if new_hash is None:
            self.engine._log.debug(f"Skipped unreadable modify: {path}")
            return

        # Optional: ignore pure‑timestamp updates where the content didn't change.
        old_hash = self._hash_cache.get(path)
        if old_hash == new_hash:
            self.engine._log.debug(f"Ignored unchanged modify: {path}")
            return

        # Content really changed → remember the new hash and (re)start timer.
        self._hash_cache[path] = new_hash
        self.engine._log.info(f"Dictionary file changed: {path}")

        # ---------- debounce ----------
        with self._lock:
            # Cancel any pending timer.
            if self._timer is not None:
                self._timer.cancel()

            # Start a fresh timer that will fire after DEBOUNCE_SECONDS.
            self._timer = threading.Timer(
                self.DEBOUNCE_SECONDS,
                self._trigger_reload   # <-- executed in a separate thread
            )
            self._timer.daemon = True   # don't block interpreter shutdown
            self._timer.start()

    # ------------------------------------------------------------------
    #  What the timer actually does
    # ------------------------------------------------------------------
    def _trigger_reload(self):
        """
        Called once the debounce interval has elapsed with no further
        modifications.  We acquire the lock again just in case a new
        event arrived right at the same moment.
        """
        with self._lock:
            # Clear the timer reference – it has fired.
            self._timer = None

        self.engine._log.info("Debounce period ended - reloading dictionary bundle")
        self.engine.reload_bundle()


class Expansion_Engine:
    _log = get_logger('ENGINE') 
    _last_end_key = ''
    def __init__(self, key_output, comms_proxy, gregg_dict) -> None:
        self.key_output = key_output
        self.comms_proxy = comms_proxy
        self.gregg_dict = gregg_dict
        raw_paths = os.getenv('DICTIONARY_PATHS', '').split(',')

        # Expand any Windows‑style %VAR% placeholders (and also ~)
        #    os.path.expandvars handles %APPDATA%, %HOME%, etc.
        #    Path(...).expanduser() handles ~ on all platforms.
        self.dictionary_paths = [
            Path(os.path.expandvars(p)).expanduser().resolve()
            for p in raw_paths if p               # skip empty entries
        ]
        # self.load_dictionary_bundle([str(p) for p in self.dictionary_paths])
        self.load_dictionary_bundle(self.dictionary_paths)
        # self._watched_directories: set[Path] = set()
        # self.MAX_TRIGGER_LEN = max(len(k) for k in self.expansions)   # longest trigger we care about
        # self.poll_interval = 0.05

        self.expansion_count = 0
        self.characters_input = 0
        self.characters_output = 0
        self.seconds_typing = 0.0

        self._log.info('Initiated Engine')
        self._start_watcher()       # Start monitoring dictionary files for changes


    def reload_bundle(self):
        """
        Reload all dictionaries and rebuild the derived structures.
        This method is safe to call from the watcher thread because it
        acquires a lock before mutating shared state.
        """
        with self._reload_lock:
            self._log.info("Reloading dictionary bundle …")
            self.load_dictionary_bundle(self.dictionary_paths)
            self._log.info("Dictionary bundle reloaded.")

    def _start_watcher(self):
        """
        Start a background thread that watches every directory that contains a
        dictionary file.  Because `self.dictionary_paths` now holds resolved
        Path objects, we can safely use `.parent` without any extra string
        manipulation.
        """
        self._reload_lock = threading.Lock()
        self._observer = Observer()
        handler = _DictChangeHandler(self)

        for dict_path in self.dictionary_paths:          # dict_path is a Path
            watch_dir = dict_path.parent                  # the folder to monitor
            '''
            if watch_dir in self._watched_directories:
                # Already watching this folder – skip duplicate schedule
                self._log.debug(f"Already watching {watch_dir}, skipping.")
                continue
            self._watched_directories.add(watch_dir)
            '''
            self._log.debug(f"Watching directory: {watch_dir}")
            self._observer.schedule(handler, str(watch_dir), recursive=False)

        # Run the observer in a daemon thread so it exits automatically
        self._observer_thread = threading.Thread(
            target=self._observer.start,
            name="DictionaryWatcher",
            daemon=True,
        )
        self._observer_thread.start()
        self._log.info("Started dictionary‑file watcher thread.")

    def stop_watcher(self):
        """Call this when the engine is shutting down (e.g., on program exit)."""
        self._observer.stop()
        self._observer.join()
        self._log.info("Dictionary watcher stopped.")

    def load_dictionary_bundle(self, dictionary_paths):
        self._log.info(f"Loading dictionary bundle from {dictionary_paths}")
        self.dictionaries = self.get_dictionaries(dictionary_paths)
        self.load_expansions()

    def get_dictionaries(self, dictionary_paths):
        self._log.info(f"Loading entries from {len(dictionary_paths)} dictionaries")
        dictionaries = {}
        for dictionary_path in dictionary_paths:
            dictionaries[dictionary_path] = self.get_dictionary(dictionary_path)
        return dictionaries 

    def get_dictionary(self, dictionary_path: Path):
        self._log.info(f"Loading entries from {dictionary_path}")

        result: dict[str, dict] = {}
            
        if dictionary_path.suffix.lower() == '.csv':
            # Open the file – `newline=''` lets csv handle newlines correctly
            with open(dictionary_path, newline='', encoding="utf-8") as f:
                reader = csv.DictReader(f, fieldnames=[
                    "word", "form", "qwerd", "keyer", "chord", "usage"
                ])

                for row in reader:
                    # Skip completely empty rows (e.g., trailing newline)
                    if not any(row.values()):
                        continue

                    # The key we want to index by
                    key = row["qwerd"]

                    # Store a shallow copy so later modifications don’t affect the
                    # original row reference held by the CSV reader.
                    result[key] = dict(row)
        else:
            with open(dictionary_path, 'r', encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line.startswith('CoachBrief'):
                        continue
                    parts = line.split('"')
                    if len(parts) != 7:
                        self._log.warning(f"Skipping malformed line in {dictionary_path}: {line}")
                        continue
                    this_key = parts[1].strip().capitalize()
                    word = parts[3].strip().capitalize()
                    shortest_key = parts[5].strip().capitalize()
                    if this_key not in result:
                        row = {"word": word, "form": "", "qwerd": this_key, "keyer": "", "chord": "", "usage": ""}
                        result[this_key] = row
                    if shortest_key not in result:
                        row = {"word": word, "form": "", "qwerd": shortest_key, "keyer": "", "chord": "", "usage": ""}
                        result[shortest_key] = row

        return result

    def load_expansions(self):
        self._log.info(f"Loading expansions from dictionaries")
        self.expansions = self.get_expansions(self.dictionaries)
        self.hints = self.build_hints(self.expansions)
        self.reverse_hints = self.build_reverse_hints(self.expansions)
        self._log.info(f"Loaded {len(self.expansions)} expansions")

    def get_expansions(self, dictionaries):
        expansions = {}
        for dictionary_path, dictionary in dictionaries.items():
            for key, value in dictionary.items():
                # if value['word'] == 'Pretty':
                #     self._log.debug(f"{key} = {value['word']} from {dictionary_path}")
                if not key:
                    self._log.warning(f"key is nothing in {value} from {dictionary_path}")
                if not key in expansions:
                    expansions[key] = value['word']
                    expansions[key.lower()] = value['word'].lower()
                    if len(key) > 1:
                        expansions[key.upper()] = value['word'].upper()
                    else:
                        # Single character keys should be proper cased
                        expansions[key.upper()] = value['word']
        
        ### Insert forced expansions
        expansions["'s"] = "'s"
        expansions["'d"] = "'d"
        expansions["'m"] = "'m"
        expansions["'r"] = "'re"
        expansions["'re"] = "'re"
        expansions["'v"] = "'ve"
        expansions["'ve"] = "'ve"
        expansions["'l"] = "'ll"
        expansions["'ll"] = "'ll"
        expansions["'t"] = "'t"
        return expansions 

    def put_expansions(self, propercased_key: str, propercased_expansion: str):
        self._log.info(f"Putting expansion {propercased_key} = {propercased_expansion}")
        self.expansions[propercased_key] = propercased_expansion
        self.expansions[propercased_key.lower()] = propercased_expansion.lower()
        if len(propercased_key) > 1:
            self.expansions[propercased_key.upper()] = propercased_expansion.upper()
        else:
            # Single character keys should be proper cased
            self.expansions[propercased_key.upper()] = propercased_expansion
        self.hints = self.build_hints(self.expansions)
        self.reverse_hints = self.build_reverse_hints(self.expansions)

    def delete_expansions(self, propercased_key: str):
        self._log.info(f"Deleting expansions for {propercased_key}")
        for key in [propercased_key, propercased_key.lower(), propercased_key.upper()]:
            if key in self.expansions:
                self._log.info(f"Deleting found expansion from {len(self.expansions)} entries")
                del self.expansions[key]
                self._log.info(f"Deleted found expansion to {len(self.expansions)} entries")
            else:
                self._log.warning(f"Cannot delete expansion for {key} as it does not exist")
        self.hints = self.build_hints(self.expansions)
        self.reverse_hints = self.build_reverse_hints(self.expansions)

    def build_hints(self, expansions):
        hints = {}
        self._log.debug(f"Building hints from expansions")
        for key, expansion in self.expansions.items():
            # self._log.debug(f"{key} = {expansion}")
            try: 
                hint_key1, hint_char1 = key[:-1], key[-1]
            except IndexError:
                self._log.warning(f"IndexError building hints for key {key}")
                continue
            if hint_key1 not in hints:
                hints[hint_key1] = []
            hints[hint_key1].append(hint_char1)
            if len(hint_key1) < 2:
                continue
            hint_key2, hint_char2 = hint_key1[:-1], hint_key1[-1]
            if hint_key2 not in hints:
                hints[hint_key2] = []
            hints[hint_key2].append(hint_char2 + hint_char1)

            if len(hints) > 2000000000:
                break

        # Sort the hints for each key by length (shortest first) and alphabetically
        for key, words in hints.items():
            words.sort(key=lambda s: (len(s), s))

        self._log.debug(f"Built hints from expansions with {len(hints)} keys")
        # sample_keys = list(hints.keys())[:10] 
        # for key in sample_keys:
            # self._log.debug(f"Hint for {key}: {hints[key]}")
        return hints
    
    def build_reverse_hints(self, expansions):
        reverse_hints = {}
        self._log.debug(f"Building reverse hints from expansions")
        for key, expansion in expansions.items():
            # self._log.debug(f"{key} = {expansion}")
            if expansion not in reverse_hints:
                reverse_hints[expansion] = key
            else:
                # Keep the shortest key for the expansion
                if len(key) < len(reverse_hints[expansion]):
                    reverse_hints[expansion] = key

        self._log.debug(f"Built reverse hints from expansions with {len(reverse_hints)} keys")
        
        return reverse_hints
    
    def expand_queue(self, queue, end_key, elapsed_time: float = 0.0):
        # Expand the given queue of keystrokes upon receiving the end_key.
        self._log.debug(f"Checking and expanding queue {queue} upon {end_key}")

        # Build the qwerd from the queue
        qwerd = ''
        for key in queue:
            self._log.debug(f"Qwerding {key}")
            qwerd += key
        self._log.debug(f"Qwerd: {qwerd}")


        replay_output = ''
        if qwerd in self.expansions:
            # We will expand this and return the expansion to the caller
            self._log.debug(f"Sending to keyout {qwerd}")
            # Handle contractions
            if self._last_end_key == "'" and f"'{qwerd}" in self.expansions:
                # In single quoted strings, a thing that *could* be a contraction will be treated as one 
                self._log.debug(f"Prepending apostrophe to {qwerd} as contraction")
                qwerd = f"'{qwerd}"

            # Replacing the qwerd triggers the scribe, 
            # so to give hints about shorter qwerds, we need to pass the shortest one
            
            if self.expansions[qwerd] in self.reverse_hints:
                if len(self.reverse_hints[self.expansions[qwerd]]) < len(qwerd):
                    hint_qwerd = f"<{self.reverse_hints[self.expansions[qwerd]]}>"
                    self.comms_proxy.signal_coach_append_misses(f"{self.reverse_hints[self.expansions[qwerd]]} = {self.expansions[qwerd]} (as {qwerd})")
                else:
                    hint_qwerd = qwerd
            else:
                hint_qwerd = qwerd

            self.key_output.replace_qwerd(qwerd, self.expansions[qwerd], end_key, hint_qwerd)
            this_characters_input = len(qwerd) + 1
            this_characters_output = len(self.expansions[qwerd]) + 1 
            self.expansion_count += 1
            replay_output = self.expansions[qwerd]
        else:
            if qwerd in self.reverse_hints:
                self._log.debug(f"Qwerd {qwerd} not found, but reverse hint exists: {self.reverse_hints[qwerd]}")
                self.key_output.log_no_action(f"<{self.reverse_hints[qwerd]}>", qwerd, end_key)
                this_characters_output = this_characters_input = len(qwerd) + 1
                if len(self.reverse_hints[qwerd]) < len(qwerd):
                    self.comms_proxy.signal_coach_append_misses(f"{self.reverse_hints[qwerd]} = {qwerd} (as {qwerd})")
            else:
                self._log.debug(f"Qwerd {qwerd} not in expansions")
                # Look for an opportunity in this if the qwerd is 4+ characters 
                if len(qwerd) >= 4:
                    opportunity = self.gregg_dict.find_best_match(qwerd)
                    if opportunity:
                        self._log.debug(f"Found opportunity for {qwerd} as {opportunity}")
                        self.comms_proxy.signal_coach_append_opportunities(f"{qwerd} appears in Gregg Dictionary, but not in expansions")
                self.key_output.log_no_action(qwerd, qwerd, end_key)
                this_characters_output = this_characters_input = len(qwerd) + 1
            
            replay_output = qwerd 
            
        # Update performance metrics
        self.characters_input += this_characters_input
        self.characters_output += this_characters_output
        # Here are the 3 pieces of data that make up the whole performance picture 
        self.seconds_typing += elapsed_time
        wpm_input = (self.characters_input / 5) / (self.seconds_typing / 60) if self.seconds_typing > 0 else 0.0
        wpm_output = (self.characters_output / 5) / (self.seconds_typing / 60) if self.seconds_typing > 0 else 0.0
        # First, the WPM portion of the display
        wpm_phrase = f"wpm: {wpm_output:.1f}({wpm_input :.1f})"
        # Second, how many seconds I spent actually typing followed by how many seconds I would have typed without the system 
        time_phrase = f" in s:{self.seconds_typing :.0f}({(self.seconds_typing * (wpm_output - wpm_input)) / wpm_input :.0f})"
        # Third, how many expansions I made
        expansion_phrase = f" over x:{self.expansion_count}"
        # Send the updated performance to the UI
        self.comms_proxy.signal_performance_updated(f"{wpm_phrase}{time_phrase}{expansion_phrase}")

        self._log.debug(f"Setting last end key to {end_key}")
        self._last_end_key = end_key

        return replay_output

    def display_hints(self, current_queue):
        # This is where the text of the hints gets built and sent to the scribe.
        qwerd = ''.join(current_queue)
        if not qwerd:
            # self.key_output.scribe.set_lower_text(" = ")
            self.comms_proxy.signal_coach_set_predictions(" = ")
            return
        word = self.expansions.get(qwerd, f"<{self.reverse_hints.get(qwerd, '∅')}>")
        current_hint = f"{qwerd} = {word}"
        # self._log.info(f"Displaying hints for {qwerd} as {word} to {current_hint}")

        # self.key_output.scribe.set_lower_text(current_hint)
        self.comms_proxy.signal_coach_set_predictions(current_hint)

        if ''.join(current_queue) in self.hints:
            hints_list = self.hints[''.join(current_queue)]
            for hint in hints_list[:30]:
                # self._log.debug(f"Hint: {hint}")
                # self.key_output.scribe.append_to_lower(f"{hint} = {self.expansions[qwerd + hint]}")
                self.comms_proxy.signal_coach_append_predictions(f"{hint} = {self.expansions[qwerd + hint]}")
            if len(hints_list) > 30:
                self._log.debug(f"Limited {len(hints_list)} hints to 30")
        else:
            # self.key_output.scribe.append_to_lower(" = ")
            self.comms_proxy.signal_coach_append_predictions(" = ")
