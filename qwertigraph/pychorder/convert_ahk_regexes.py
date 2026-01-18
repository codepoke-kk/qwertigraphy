import json
import re
from pathlib import Path
from typing import List, Dict

# ----------------------------------------------------------------------
# Helper: read the AHK file and turn the rule lines into a list of dicts
# ----------------------------------------------------------------------
def parse_ahk_rules(ahk_path: Path) -> List[Dict[str, str]]:
    """
    Reads an AHK‑style rule file and returns a list of dictionaries:
        {"pattern": <regex>, "abbrev": <regex>, "replace": <text>}
    Blank lines and comment lines (starting with ';') are ignored.
    The remaining lines are expected to contain exactly three comma‑separated
    fields: word‑regex, abbreviation‑regex, replacement‑text.
    """
    rules = []
    comment = ""
    with ahk_path.open(encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            # Skip empty lines and pure comments
            if not line:
                continue

            if line.startswith(";"):
                comment = line[1:].strip()
                continue

            # Split on commas – the AHK format never escapes commas inside a field,
            # so a simple split works.
            parts = [p.strip() for p in line.split(",")]
            if len(parts) != 3:
                # If the line does not have exactly three parts we raise a clear error.
                raise ValueError(f"Invalid rule line (expected 3 comma‑separated parts): {line}")

            pattern, abbrev, replace = parts
            rules.append({"comment": comment, "word_pattern": pattern, "form_pattern": abbrev, "replace": replace})
            comment = ""
    return rules


# ----------------------------------------------------------------------
# Write the parsed rules to JSON (pretty‑printed for readability)
# ----------------------------------------------------------------------
def export_to_json(rules: List[Dict[str, str]], json_path: Path) -> None:
    json_path.write_text(json.dumps(rules, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ Exported {len(rules)} rules to {json_path}")


# ----------------------------------------------------------------------
# Example usage
# ----------------------------------------------------------------------
if __name__ == "__main__":
    ahk_file = Path(r"C:\Users\kevin\OneDrive\Documents\GitHub\qwertigraphy\qwertigraph\classes\uniform_patterns.txt")          # ← put your AHK list here
    json_file = Path("uniform_patterns.json")

    rules = parse_ahk_rules(ahk_file)
    export_to_json(rules, json_file)