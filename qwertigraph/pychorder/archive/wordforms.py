

import re
import sys
from typing import Set

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
    forms = {word}
    forms.update(_regular_verb_forms(word))
    return forms

# ----------------------------------------------------------------------
# 4️⃣ Public API
# ----------------------------------------------------------------------
def get_all_forms(word: str) -> Set[str]:
    if not isinstance(word, str) or not word:
        return set()

    base = word.lower()
    forms = {base}

    # Verb inflections (if applicable)
    forms.update(_verb_forms(base))

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