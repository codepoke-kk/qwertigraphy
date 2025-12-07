import time
from log_factory import get_logger
import os
import csv
from pathlib import Path
from engine_signal_proxy import EngineSignalProxy

class Expansion_Engine:
    _log = get_logger('ENGINE') 
    _last_end_key = ''
    def __init__(self, key_output, engine_signals: 'EngineSignalProxy'):
        self.engine_signals = engine_signals
        self.key_output = key_output
        self.dictionary_paths = os.getenv('DICTIONARY_PATHS').split(',')
        self.dictionaries = self.get_dictionaries(self.dictionary_paths)
        self._log.info(f"Loaded {len(self.dictionaries)} dictionaries")
        self.expansions = self.get_expansions(self.dictionaries)
        self.hints = self.build_hints(self.expansions)
        self.reverse_hints = self.build_reverse_hints(self.expansions)
        # for key, expansion in self.expansions.items():
        #     self._log.debug(f"{key} = {expansion}")
        self._log.info(f"Loaded {len(self.expansions)} expansions")
        # self.MAX_TRIGGER_LEN = max(len(k) for k in self.expansions)   # longest trigger we care about
        # self.poll_interval = 0.05

        self.expansion_count = 0
        self.characters_input = 0
        self.characters_output = 0
        self.seconds_typing = 0.0

        self._log.info('Initiated Engine')

    def get_dictionaries(self, dictionary_paths):
        self._log.info(f"Loading entries from {len(dictionary_paths)} dictionaries")
        dictionaries = {}
        for dictionary_path in dictionary_paths:
            dictionaries[dictionary_path] = self.get_dictionary(dictionary_path)
        return dictionaries 

    def get_dictionary(self, dictionary_path):
        self._log.info(f"Loading entries from {dictionary_path}")

        result: dict[str, dict] = {}

        if 'APPDATA' in os.environ and dictionary_path.startswith('%APPDATA%'):
            appdata_path = os.environ['APPDATA']
            dictionary_path = dictionary_path.replace('%APPDATA%', appdata_path)
            
        if dictionary_path.endswith('csv'):
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

    def get_expansions(self, dictionaries):
        expansions = {}
        for dictionary_path, dictionary in dictionaries.items():
            for key, value in dictionary.items():
                # if value['word'] == 'Pretty':
                #     self._log.debug(f"{key} = {value['word']} from {dictionary_path}")
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

    def build_hints(self, expansions):
        hints = {}
        self._log.debug(f"Building hints from expansions")
        for key, expansion in self.expansions.items():
            # self._log.debug(f"{key} = {expansion}")
            hint_key1, hint_char1 = key[:-1], key[-1]
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
        self._log.debug(f"Checking and expanding queue {queue} upon {end_key}")

        # Build the qwerd from the queue
        qwerd = ''
        for key in queue:
            self._log.debug(f"Qwerding {key}")
            qwerd += key
        self._log.debug(f"Qwerd: {qwerd}")


        if qwerd in self.expansions:
            self._log.debug(f"Sending to keyout {qwerd}")
            # Handle contractions
            if self._last_end_key == "'":
                self._log.debug(f"Prepending apostrophe to {qwerd} as contraction")
                qwerd = f"'{qwerd}"
            self.key_output.replace_qwerd(qwerd, self.expansions[qwerd], end_key)
            this_characters_input = len(qwerd) + 1
            this_characters_output = len(self.expansions[qwerd]) + 1 
            self.expansion_count += 1
        else:
            if qwerd in self.reverse_hints:
                word = qwerd 
                self._log.debug(f"Qwerd {qwerd} not found, but reverse hint exists: {self.reverse_hints[qwerd]}")
                self.key_output.log_no_action(f"<{self.reverse_hints[qwerd]}>", word, end_key)
                this_characters_output = this_characters_input = len(word) + 1
            else:
                self._log.debug(f"Qwerd {qwerd} not in expansions")
                self.key_output.log_no_action(qwerd, qwerd, end_key)
                this_characters_output = this_characters_input = len(qwerd) + 1
            
        # Update performance metrics
        self.characters_input += this_characters_input
        self.characters_output += this_characters_output
        self.seconds_typing += elapsed_time
        wpm_input = (self.characters_input / 5) / (self.seconds_typing / 60) if self.seconds_typing > 0 else 0.0
        wpm_output = (self.characters_output / 5) / (self.seconds_typing / 60) if self.seconds_typing > 0 else 0.0
        self.engine_signals.emit_performance_updated(f"{self.characters_input}/{self.characters_output} chars at {wpm_input :.1f}/{wpm_output:.1f} WPM for {self.expansion_count} expansions in {self.seconds_typing :.1f} seconds")

        self._last_end_key = end_key

    def display_hints(self, current_queue):
        # This is where the text of the hints gets built and sent to the scribe.
        qwerd = ''.join(current_queue)
        if not qwerd:
            self.key_output.scribe.set_lower_text(" = ")
            return
        word = self.expansions.get(qwerd, f"<{self.reverse_hints.get(qwerd, '∅')}>")
        current_hint = f"{qwerd} = {word}"
        # self._log.info(f"Displaying hints for {qwerd} as {word} to {current_hint}")

        self.key_output.scribe.set_lower_text(current_hint)

        if ''.join(current_queue) in self.hints:
            hints_list = self.hints[''.join(current_queue)]
            for hint in hints_list:
                # self._log.debug(f"Hint: {hint}")
                self.key_output.scribe.append_to_lower(f"{hint} = {self.expansions[qwerd + hint]}")
        else:
            self.key_output.scribe.append_to_lower(" = ")
