import time
from log_factory import get_logger
import os
import csv
from pathlib import Path

class Expansion_Engine:
    _log = get_logger('ENGINE') 
    def __init__(self, key_output):
        self.key_output = key_output
        self.dictionary_paths = os.getenv('DICTIONARY_PATHS').split(',')
        self.dictionaries = self.get_dictionaries(self.dictionary_paths)
        self._log.info(f"Loaded {len(self.dictionaries)} dictionaries")
        self.expansions = self.get_expansions(self.dictionaries)
        # for key, expansion in self.expansions.items():
        #     self._log.debug(f"{key} = {expansion}")
        self._log.info(f"Loaded {len(self.expansions)} expansions")
        self.MAX_TRIGGER_LEN = max(len(k) for k in self.expansions)   # longest trigger we care about
        self.poll_interval = 0.05

        self.enabled = False 
        self._log.info('Initiated Key Input')

    def get_dictionaries(self, dictionary_paths):
        self._log.info(f"Loading entries from {len(dictionary_paths)} dictionaries")
        dictionaries = {}
        for dictionary_path in dictionary_paths:
            dictionaries[dictionary_path] = self.get_dictionary(dictionary_path)
        return dictionaries 

    def get_dictionary(self, dictionary_path):
        self._log.info(f"Loading entries from {dictionary_path}")

        result: dict[str, dict] = {}

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
        return expansions 

    def expand_queue(self, queue, end_key):
        if not self.enabled:
            return 
        self._log.debug(f"Checking and expanding queue {queue} upon {end_key}")
        qwerd = ''
        for key in queue:
            self._log.debug(f"Qwerding {key}")
            qwerd += key.char
        self._log.debug(f"Qwerd: {qwerd}")
        if qwerd in self.expansions:
            self._log.debug(f"Sending to keyout {qwerd}")
            self.key_output.replace_qwerd(qwerd, self.expansions[qwerd], end_key)
        else:
            self._log.debug(f"Qwerd {qwerd} not in expansions")

    def engine_loop(self):
        self._log.debug(f"Not looping")
        while True:
            try: 
                time.sleep(20)
                notes = self.key_output.scribe.readback_notes()
                for note in notes:
                    print(f"{note.key:<6}{note.word:<30}{note.end_key_str:>6}")
            except KeyboardInterrupt:
                print("\nStopped.")
                break
        
        '''
        while True:
            # Look at the most recent characters (up to the longest trigger)
            tail = ''.join(self.key_queue.keystroke_queue[-self.MAX_TRIGGER_LEN:])
            for trigger, expansion in self.expansions.items():
                if tail.endswith(trigger):
                    # We have a match – hand it off to the output component
                    self.key_output.replace_trigger(trigger, expansion)
                    break
            time.sleep(self.poll_interval)
        '''