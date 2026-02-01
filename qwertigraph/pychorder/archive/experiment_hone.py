import json
import difflib
from pathlib import Path
from typing import List, Tuple, Dict, Any, Optional


def load_data(json_path: str) -> List[Dict[str, Any]]:
    """
    Load the JSON file that contains a list of pages.
    Each element looks like:
        {"page":"001","words":[{"t":"abduction","x":1117,"y":1176}, … ]}
    """
    with open(json_path, "r", encoding="utf-8") as f:
        # The file may contain line‑breaks or trailing commas – json.load handles it.
        data = json.load(f)
    return data


def similarity(a: str, b: str) -> float:
    """
    Normalised similarity (0‑1) between two strings.
    `difflib.SequenceMatcher` gives a quick, lightweight approximation.
    """
    return difflib.SequenceMatcher(None, a.lower(), b.lower()).ratio()


def find_best_match(
    data: List[Dict[str, Any]],
    query: str,
    *,
    min_ratio: float = 0.3,
) -> Optional[Tuple[str, str, int, int]]:
    """
    Scan the whole data set and return the entry that best matches ``query``.

    Returns
    -------
    (page, word, x, y)  or  None  if nothing meets ``min_ratio``.
    """
    best: Tuple[float, Optional[Tuple[str, str, int, int]]] = (0.0, None)

    for page_obj in data:
        page_no = page_obj["page"]
        for w in page_obj["words"]:
            word = w["t"]
            # Quick pre‑filter – does the query appear as a substring?
            if query.lower() not in word.lower():
                continue

            # Compute a similarity score; higher is better.
            score = similarity(query, word)

            # Keep the highest‑scoring candidate.
            if score > best[0]:
                best = (score, (page_no, word, w["x"], w["y"]))

    # If the best score is still below the threshold we treat it as “no good match”.
    if best[0] >= min_ratio:
        return best[1]
    return None


# ----------------------------------------------------------------------
# Example usage
# ----------------------------------------------------------------------
if __name__ == "__main__":
    # Replace this path with wherever you stored the JSON snippet.
    json_file = Path("greggdict/reference.json")

    # Load the data once – it can be reused for many queries.
    dataset = load_data(str(json_file))

    # ------------------------------------------------------------------
    # Query examples
    # ------------------------------------------------------------------
    queries = ["yeas", "abdu", "wrathful", "zinc", "zzzzz"]

    for q in queries:
        result = find_best_match(dataset, q)
        if result:
            page, word, x, y = result
            print(
                f'Query "{q}" → page {page}, word "{word}", coordinates ({x}, {y})'
            )
        else:
            print(f'Query "{q}" → no sufficiently close match found.')