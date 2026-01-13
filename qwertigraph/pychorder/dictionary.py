import csv
from pathlib import Path
from typing import List, Dict, Optional
import os
from log_factory import get_logger


class Entry:
    """
    One row of the dictionary.
    Fields:
        word, form, qwerd, keyer, chord, usage, source
    """
    __slots__ = ('word', 'form', 'qwerd', 'keyer', 'chord', 'usage', 'source')

    def __init__(self,
                 word: str,
                 form: str,
                 qwerd: str,
                 keyer: str,
                 chord: str,
                 usage: str,
                 source: str):
        self.word = word
        self.form = form
        self.qwerd = qwerd
        self.keyer = keyer
        self.chord = chord
        self.usage = usage
        self.source = source

    @classmethod
    def from_csv_row(cls, row: List[str], source: str) -> "Entry":
        """Create an Entry from a CSV row (six fields) and a source name."""
        if len(row) != 6:
            raise ValueError(f'Expected 6 columns, got {len(row)}: {row}')
        return cls(*row, source)

    def to_csv_row(self) -> List[str]:
        """Return the six original fields – used when persisting a source file."""
        return [self.word, self.form, self.qwerd,
                self.keyer, self.chord, self.usage]

    def to_dict(self) -> Dict[str, str]:
        """Convenient dict representation (all seven fields)."""
        return {
            'word': self.word,
            'form': self.form,
            'qwerd': self.qwerd,
            'keyer': self.keyer,
            'chord': self.chord,
            'usage': self.usage,
            'source': self.source,
        }

    def __repr__(self) -> str:
        return f"<Entry {self.word!r} ({self.form}/{self.qwerd}/{self.keyer}/{self.chord}/{self.usage}/{self.source})>"

    def __iter__(self):
        # The order must match HEADER_LABELS / the UI column order
        yield self.word
        yield self.form
        yield self.qwerd
        yield self.keyer
        yield self.chord
        yield self.usage
        yield self.source

    # (Optional) make it behave like a sequence for indexing
    def __len__(self):
        return len(self.__slots__)

    def __getitem__(self, idx):
        return getattr(self, self.__slots__[idx])

    def clone(self) -> "Entry":
        """
        Return a shallow copy of this Entry.

        The new object has the same values for all slots, but it is a distinct
        instance, so mutating one will not affect the other.
        """
        # Using the constructor keeps the logic in one place.
        return Entry(
            self.word,
            self.form,
            self.qwerd,
            self.keyer,
            self.chord,
            self.usage,
            self.source,
        )
    
    def get_items_list(self) -> List[str]:
        """
        Return a list of all fields in order.
        """
        return [
            self.word,
            self.form,
            self.qwerd,
            self.keyer,
            self.chord,
            self.usage,
            self.source,
        ]

class Source_Dictionary:
    """
    Holds entries that belong to a single CSV file.
    Provides CRUD and can write the six original fields back to disk.
    """
    def __init__(self, name: str, csv_path: Path):
        """
        Parameters
        ----------
        name: short identifier used for the `source` field (e.g. "SD1")
        csv_path: location of the CSV file containing the six-field rows
        """
        self.name = name
        self.path = Path(os.path.expandvars(csv_path)).expanduser().resolve()
        # self.path = Path(csv_path)
        self.entries: Dict[str, Entry] = {}          # keyed by primary key (word)
        self._load()

    # ------------------------------------------------------------------ #
    # Loading / saving
    # ------------------------------------------------------------------ #
    def _load(self) -> None:
        """Read the CSV file and populate `self.entries`."""

        if not self.path.exists():
            # raise FileNotFoundError(f"Source file not found: {self.path}")
            print(f"*** File not found {self.path}")
            print(f"(Handle this error better)")
            return 

        with self.path.open(newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                try:
                    entry = Entry.from_csv_row(row, source=self.name)
                except ValueError as e:
                    # Skip malformed rows but keep processing the rest
                    print(f"[{self.name}] Skipping bad row: {e}")
                    continue
                self.entries[self._key_of(entry)] = entry

    def save(self) -> None:
        """Write the six original fields back to the CSV file, sorted by qwerd."""
        # Sort the Entry objects by their `qwerd` attribute (case‑insensitive)
        sorted_entries = sorted(
            self.entries.values(),
            key=lambda e: e.qwerd.lower()   # use .lower() for a case‑insensitive order
        )

        print(f"Saving {len(sorted_entries)} entries to {self.path}")
        with self.path.open('w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            for entry in sorted_entries:
                writer.writerow(entry.to_csv_row())

    # ------------------------------------------------------------------ #
    # CRUD helpers (internal)
    # ------------------------------------------------------------------ #
    @staticmethod
    def _key_of(entry: Entry) -> str:
        """Define the uniqueness key for an entry inside a source."""
        return entry.qwerd  # you can change this to a tuple of fields if needed

    # ------------------------------------------------------------------ #
    # Public CRUD API
    # ------------------------------------------------------------------ #
    def put (self, entry: Entry) -> None:
        """Add or replace a new entry"""
        key = self._key_of(entry)
        self.entries[key] = entry

    def create(self, entry: Entry) -> None:
        """Add a new entry; raises if the key already exists."""
        key = self._key_of(entry)
        if key in self.entries:
            raise KeyError(f"Entry with key '{key}' already exists in {self.name}")
        self.entries[key] = entry

    def read(self, key: str) -> Optional[Entry]:
        """Retrieve an entry by its key (or None if missing)."""
        return self.entries.get(key)

    def update(self, entry: Entry) -> None:
        """Replace an existing entry; raises if it does not exist."""
        key = self._key_of(entry)
        if key not in self.entries:
            raise KeyError(f"No entry with key '{key}' in {self.name}")
        self.entries[key] = entry

    def delete(self, key: str) -> None:
        """Remove an entry; silently ignores missing keys."""
        print(f"Count of entries before delete: {len(list(self.entries.keys()))}")
        self.entries.pop(key, None)
        print(f"Count of entries after delete: {len(list(self.entries.keys()))}")

    # ------------------------------------------------------------------ #
    # Convenience
    # ------------------------------------------------------------------ #
    def all_entries(self) -> List[Entry]:
        """Return a list of all entries currently held."""
        return list(self.entries.values())
    
class Composite_Dictionary:
    _log = get_logger('DICT') 
    def __init__(self, sources: List[Source_Dictionary]):
        # if not (2 <= len(sources) <= 8):
        #     raise ValueError("Composite_Dictionary requires 2‑8 source dictionaries.")
        self.sources = sources

        # Unified index: key → Entry (the first one encountered)
        self._index: Dict[str, Entry] = {}
        self._build_index()
        self._log.info("Composite Dictionary initialized")

    # ------------------------------------------------------------------ #
    # Index construction
    # ------------------------------------------------------------------ #
    def _build_index(self) -> None:
        """Populate the composite view, respecting “first wins” semantics."""
        self._index.clear()
        for src in self.sources:
            for entry in src.all_entries():
                key = self._key_of(entry)
                if key not in self._index:
                    self._index[key] = entry
                # else: duplicate – ignore for the composite view

    @staticmethod
    def _key_of(entry: Entry) -> str:
        """Same uniqueness rule as Source_Dictionary (currently word)."""
        return entry.qwerd

    # ------------------------------------------------------------------ #
    # Composite CRUD – public API
    # ------------------------------------------------------------------ #
    def put(self, entry: Entry) -> None:
        """
        Add or replace an entry:
          * It must specify a valid `source` that matches one of the contained
            Source_Dictionary names.
          * The entry is inserted into that source (persisted later via `save_all`)
          * The composite index is refreshed.
        """
        target_src = self._find_source(entry.source)
        if not target_src:
            raise ValueError(f"Unknown source '{entry.source}'. Available: "
                             f"{[s.name for s in self.sources]}")

        key = self._key_of(entry)
        target_src.put(entry) 
        self._index[key] = entry 

    def create(self, entry: Entry) -> None:
        """
        Add a new entry:
          * It must specify a valid `source` that matches one of the contained
            Source_Dictionary names.
          * The entry is inserted into that source (persisted later via `save_all`)
          * The composite index is refreshed.
        """
        target_src = self._find_source(entry.source)
        if not target_src:
            raise ValueError(f"Unknown source '{entry.source}'. Available: "
                             f"{[s.name for s in self.sources]}")

        # Ensure we don’t accidentally keep a duplicate in the composite view
        key = self._key_of(entry)
        if key in self._index:
            # Remove the old occurrence from its original source
            old_entry = self._index[key]
            old_src = self._find_source(old_entry.source)
            if old_src:
                old_src.delete(key)

        target_src.create(entry)          # may raise if key already exists there
        self._index[key] = entry           # now the composite sees the new entry

    def read(self, key: str) -> Optional[Entry]:
        """Lookup by key (word). Returns the first‑loaded entry or None."""
        return self._index.get(key)

    def update(self, entry: Entry) -> None:
        """
        Update an existing entry. The entry’s `source` determines where the
        updated record lives. The old version is removed from its previous
        source (if the source changed) and written to the new one.
        """
        if entry.source not in [s.name for s in self.sources]:
            raise ValueError(f"Invalid source '{entry.source}'")

        key = self._key_of(entry)
        old_entry = self._index.get(key)

        if old_entry:
            # Delete from the source where the old entry lived (could be same)
            old_src = self._find_source(old_entry.source)
            if old_src:
                old_src.delete(key)

        # Insert/replace in the target source
        target_src = self._find_source(entry.source)
        target_src.update(entry) if old_entry else target_src.create(entry)

        # Refresh the composite index (fast path)
        self._index[key] = entry

    def delete(self, key: str) -> None:
        """Delete an entry from *all* sources and from the composite view."""
        self._log.debug(f"Deleting {key}")
        entry = self._index.pop(key, None)
        if entry:
            self._log.debug(f"Found entry to delete: {entry}")
            src = self._find_source(entry.source)
            if src:
                self._log.debug(f"Deleting: {entry} from source {src.name}")
                src.delete(key)

    # ------------------------------------------------------------------ #
    # Helper utilities
    # ------------------------------------------------------------------ #
    def _find_source(self, name: str) -> Optional[Source_Dictionary]:
        """Return the Source_Dictionary whose `name` matches `name`."""
        for src in self.sources:
            if src.name == name:
                return src
        return None

    def all_entries(self) -> List[Entry]:
        """Composite view – list of unique entries (≈40 k)."""
        return list(self._index.values())

    def get_source_names(self):
        sources = []
        for source in self.sources:
            sources.append(source.name)
        return sources 
    
    # ------------------------------------------------------------------ #
    # Persistence
    # ------------------------------------------------------------------ #
    def save_all(self) -> None:
        """Ask every Source_Dictionary to write its CSV file."""
        for src in self.sources:
            src.save()



if __name__ == "__main__":
    # Example CSV files (create them beforehand or let the script generate empty ones)
    src1 = Source_Dictionary(name="anniversary_uniform_core.csv", csv_path="dictionaries/anniversary_uniform_core.csv")
    src2 = Source_Dictionary(name="anniversary_uniform_supplement.csv", csv_path="dictionaries/anniversary_uniform_supplement.csv")

    comp = Composite_Dictionary([src1, src2])

    # Show count
    print(f"Composite contains {len(comp.all_entries())} unique entries.")

    # Add a test entry
    test = Entry(
        word="shizzez",
        form="sh-sh-sh",
        qwerd="zzz",
        keyer="",
        chord="qz",
        usage="0",
        source="anniversary_uniform_supplement.csv"
    )
    comp.create(test)
    print("After adding:", comp.read("zzz"))

    # Persist
    comp.save_all()
    print("Saved all sources.")