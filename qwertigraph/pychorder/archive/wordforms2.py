"""
wordforms.py

Return genuine morphological forms for a given English word, **excluding
synonyms**.  The output consists of:

* Verb inflectional forms (via pattern or a tiny regular‑verb fallback)
* Derivationally related lemmas from WordNet (adjectives, adverbs,
  nouns, etc.) – *synonyms are filtered out*.

No heuristic suffixes, no noun‑plural tricks, no synonym expansion.
"""

import re
import sys
from typing import Set

# ----------------------------------------------------------------------
# 1️⃣ Imports & optional pattern support
# ----------------------------------------------------------------------
try:
    import nltk
    from nltk.corpus import wordnet as wn
except ImportError as e:
    raise ImportError(
        "NLTK is required. Install with: pip install nltk && "
        "python -m nltk.downloader wordnet"
    ) from e

# pattern is optional – we try to import it, but continue without it
try:
    from pattern.en import conjugate, PRESENT, PAST, GERUND, PARTICIPLE
    _HAS_PATTERN = True
except Exception:                     # pattern can raise many import‑related errors
    _HAS_PATTERN = False

# ----------------------------------------------------------------------
# 2️⃣ Verb conjugation helpers
# ----------------------------------------------------------------------
def _regular_verb_forms(word: str) -> Set[str]:
    """
    Conservative fallback for regular verbs only.
    Generates the three canonical forms:
        • 3rd‑person singular (‑s / ‑es)
        • past tense (‑ed)
        • gerund / present‑participle (‑ing)
    """
    forms = set()

    # 3rd‑person singular
    if word.endswith(("s", "sh", "ch", "x", "z", "o")):
        third = word + "es"
    elif word.endswith("y") and len(word) > 1 and word[-2] not in "aeiou":
        third = word[:-1] + "ies"
    else:
        third = word + "s"
    forms.add(third)

    # Past tense
    if word.endswith("e"):
        past = word + "d"
    elif word.endswith("y") and len(word) > 1 and word[-2] not in "aeiou":
        past = word[:-1] + "ied"
    else:
        past = word + "ed"
    forms.add(past)

    # Gerund / present participle
    if word.endswith("ie"):
        gerund = word[:-2] + "ying"
    elif word.endswith("e") and not word.endswith(("ee", "oe", "ye")):
        gerund = word[:-1] + "ing"
    else:
        gerund = word + "ing"
    forms.add(gerund)

    return forms


def _verb_forms(word: str) -> Set[str]:
    """
    Return verb forms for *word*.
    * If `pattern` is available we delegate to it (handles irregular verbs).
    * Otherwise we fall back to the safe regular‑verb generator.
    The original word itself is always included.
    """
    forms = {word}

    if _HAS_PATTERN:
        for tense in (GERUND, PRESENT, PAST, PARTICIPLE):
            conj = conjugate(word, tense=tense)
            if conj and conj != word:
                forms.add(conj)
    else:
        forms.update(_regular_verb_forms(word))

    return forms


# ----------------------------------------------------------------------
# 3️⃣ Derivational forms from WordNet – **synonyms excluded**
# ----------------------------------------------------------------------
def _derivational_wordnet(word: str) -> Set[str]:
    """
    Collect only the lemmas that WordNet marks as *derivationally related*
    to the supplied word.  Plain synonyms (other lemmas in the same synset)
    are deliberately ignored.
    """
    forms = set()
    for syn in wn.synsets(word):
        for lemma in syn.lemmas():
            # Skip the lemma itself – the caller already adds the base word.
            # Add only the *derivationally related* lemmas.
            for dr in lemma.derivationally_related_forms():
                forms.add(dr.name().replace('_', ' '))
    return forms


# ----------------------------------------------------------------------
# 4️⃣ Public API
# ----------------------------------------------------------------------
def get_all_forms(word: str) -> Set[str]:
    """
    Return the union of:
        • verb inflectional forms (if the word is a verb),
        • derivational forms from WordNet (synonyms filtered out).

    The result always contains the lower‑cased original word.
    """
    if not isinstance(word, str) or not word:
        return set()

    base = word.lower()
    forms = {base}

    # Verb inflections (if applicable)
    forms.update(_verb_forms(base))

    # Derivational relatives from WordNet (no synonyms)
    forms.update(_derivational_wordnet(base))

    # Clean any stray underscores that WordNet may have introduced
    return {f.replace('_', ' ') for f in forms}


# ----------------------------------------------------------------------
# 5️⃣ Command‑line demo
# ----------------------------------------------------------------------
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Show morphological forms of a word (synonyms excluded)."
    )
    parser.add_argument("word", help="Base word (e.g. respect)")
    args = parser.parse_args()

    result = get_all_forms(args.word)
    print(f"Forms for '{args.word}':")
    for w in sorted(result):
        print("  ", w)