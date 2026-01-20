import json
import re
from pathlib import Path
from typing import List, Dict

# --------------------------------------------------------------
# Load the JSON rules (order matters!)
# --------------------------------------------------------------
def load_rules(json_path: Path) -> List[Dict[str, str]]:
    return json.loads(json_path.read_text(encoding="utf-8"))


# --------------------------------------------------------------
# Apply the rules sequentially
# --------------------------------------------------------------
def transform(word: str, form: str, rules: List[Dict[str, str]]) -> str:
    """
    For each rule we run two regex substitutions:
      1. Replace any occurrence matching `pattern`.
      2. Replace any occurrence matching `abbrev`.
    The replacement string is taken verbatim from the rule.
    The function returns the final transformed string.
    """
    for rule in rules:
        word_pattern = re.compile(rule["word_pattern"])
        form_pattern = re.compile(rule["form_pattern"])

        if not word_pattern.search(word) and not form_pattern.search(form):
            continue

        # Second substitution (abbreviation pattern)
        form = form_pattern.sub(rule["replace"], form)

    return form


# --------------------------------------------------------------
# Demo / test
# --------------------------------------------------------------
if __name__ == "__main__":
    json_file = Path("uniform_patterns.json")
    rules = load_rules(json_file)

    # Example input you gave:
    start_word = 'noknox'
    start_form = "^-n--n-o-k-s"
    result = transform(start_word, start_form, rules)

    print(f"Input : {start_form} ({start_word})")
    print(f"Output: {result}")   # Expected: nnox