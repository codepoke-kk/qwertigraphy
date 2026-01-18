
from log_factory import get_logger
from dictionary import Entry

class Inflector:
    _log = get_logger('INFLK') 

    def __init__(self):
        self._log.info("Inflector initialized")

    def inflect(self, source_entry: Entry, inflection: str) -> set:
        self._log.debug(f"Inflecting entry: {source_entry}")
        entry = source_entry.clone()

        # An inflected entry should never be stored as coming from the core dictionary
        if entry.source == 'anniversary_uniform_core.csv':
            self._log.debug("Entry is from core dictionary; setting to supplement")
            entry.source = 'anniversary_uniform_supplement.csv'

        if inflection == 'S':  
            entry = self._inflect_plural(entry)
        elif inflection == 'D':  
            entry = self._inflect_past(entry)
        elif inflection == 'G':  
            entry = self._inflect_gerund(entry)
        elif inflection == 'ER':  
            entry = self._inflect_noun4(entry)
        elif inflection == 'OR':  
            entry = self._inflect_noun5(entry)
        elif inflection == 'LY':    
            entry = self._inflect_adverb(entry)
        elif inflection == 'ALLY':    
            entry = self._inflect_adverb2(entry)
        elif inflection == 'ION':   
            entry = self._inflect_noun(entry)
        elif inflection == 'ATION':   
            entry = self._inflect_noun2(entry)
        elif inflection == 'ABLE':  
            entry = self._inflect_adj(entry)
        elif inflection == 'ABILITY':  
            entry = self._inflect_adj2(entry)
        elif inflection == 'FUL':  
            entry = self._inflect_adj3(entry)
        elif inflection == 'NESS':  
            entry = self._inflect_adj4(entry)
        elif inflection == 'MENT':  
            entry = self._inflect_noun3(entry)
        else:
            self._log.warning(f"Unknown inflection type: {inflection}")
        return entry 

    def _inflect_plural(self, entry: Entry) -> str:
        entry.form = entry.form + '-s'
        entry.qwerd = entry.qwerd + 's'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('y') and len(entry.word) > 1 and entry.word[-2] not in 'aeiou':
            entry.word = entry.word[:-1] + 'ies'
        elif entry.word.endswith(('s', 'sh', 'ch', 'x', 'z', 'o')):
            entry.word = entry.word + 'es'
        else:
            entry.word = entry.word + 's'
        return entry
    
    def _inflect_past(self, entry: Entry) -> str:
        entry.form = entry.form + '-d'
        entry.qwerd = entry.qwerd + 'd'
        if entry.word.endswith('e'):
            entry.word = entry.word + 'd'
        elif entry.word.endswith('y') and len(entry.word) > 1 and entry.word[-2] not in 'aeiou':
            entry.word = entry.word[:-1] + 'ied'
        else:
            entry.word = entry.word + 'ed'
        return entry
    
    def _inflect_gerund(self, entry: Entry) -> str:
        entry.form = entry.form + r'-\-h'
        entry.qwerd = entry.qwerd + 'g'
        if entry.word.endswith('ie'):
            entry.word = entry.word[:-2] + 'ying'
        elif entry.word.endswith('e') and not entry.word.endswith(('ee', 'oe', 'ye')):
            entry.word = entry.word[:-1] + 'ing'
        else:
            entry.word = entry.word + 'ing'
        return entry
        
    def _inflect_adverb(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-e'
        entry.qwerd = entry.qwerd + 'e'      
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('le'):
            entry.word = entry.word[:-2] + 'ly'
        else:
            entry.word = entry.word + 'ly'
        return entry
        
    def _inflect_adverb2(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-e'
        entry.qwerd = entry.qwerd + 'e'      
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('le'):
            entry.word = entry.word[:-2] + 'ally'
        else:
            entry.word = entry.word + 'ally'
        return entry

    def _inflect_noun(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-sh'
        entry.qwerd = entry.qwerd + 'z'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('e'):
            entry.word = entry.word[:-1] + 'ion'
        else:
            entry.word = entry.word + 'ion'
        return entry

    def _inflect_noun2(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-sh'
        entry.qwerd = entry.qwerd + 'z'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('e'):
            entry.word = entry.word[:-1] + 'ation'
        else:
            entry.word = entry.word + 'ation'
        return entry

    def _inflect_noun3(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-m'
        entry.qwerd = entry.qwerd + 'm'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        entry.word = entry.word + 'ment'
        return entry

    def _inflect_noun4(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-r'
        entry.qwerd = entry.qwerd + 'r'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('e'):
            entry.word = entry.word + 'r'
        else:
            entry.word = entry.word + 'er'
        return entry

    def _inflect_noun5(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-r'
        entry.qwerd = entry.qwerd + 'r'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        if entry.word.endswith('e'):
            entry.word = entry.word[:-1] + 'or'
        else:
            entry.word = entry.word + 'or'
        return entry

    def _inflect_adj(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-b'
        entry.qwerd = entry.qwerd + 'b'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        entry.word = entry.word + 'able'   
        return entry

    def _inflect_adj2(self, entry: Entry) -> Entry:
        entry.form = entry.form + r'-\-b'
        entry.qwerd = entry.qwerd + 'bo'
        entry.keyer = 'o'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        entry.word = entry.word + 'ability'  
        return entry

    def _inflect_adj3(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-f'
        entry.qwerd = entry.qwerd + 'f'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        entry.word = entry.word + 'ful'  
        return entry

    def _inflect_adj4(self, entry: Entry) -> Entry:
        entry.form = entry.form + '-n'
        entry.qwerd = entry.qwerd + 'n'
        entry.chord = f"q{''.join(sorted(set(entry.qwerd.lower())))}"

        entry.word = entry.word + 'ness'  
        return entry
# ----------------------------------------------------------------------
# 5️⃣ Command‑line demo
# ----------------------------------------------------------------------
if __name__ == "__main__":
    import argparse

    inflector = Inflector()
    entry_array = ['Reference', 'r-f', 'Rf', '', 'qfr', '285', 'anniversary_uniform_core.csv']
    entry = Entry(*entry_array)
    print(f"Entry: {entry}")

    result = inflector.inflect(entry, 'S')
    print(f"Form for '{entry}': {result}")
    result = inflector.inflect(entry, 'D')
    print(f"Form for '{entry}': {result}")
    result = inflector.inflect(entry, 'G')
    print(f"Form for '{entry}': {result}")