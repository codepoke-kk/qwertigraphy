import json
import difflib
from pathlib import Path
from typing import List, Tuple, Dict, Any, Optional
import urllib.parse
import subprocess, sys

from log_factory import get_logger

class Gregg_Dict:
    _log = get_logger('GREGG') 
    json_file = Path("gregg_dict/reference.json")    

    def __init__(self):
        self.dataset = self.load_data(self.json_file)
        self._log.info("Gregg Dictionary initialized")

    def load_data(self, json_path: str) -> List[Dict[str, Any]]:
        with open(json_path, "r", encoding="utf-8") as f:
            # The file may contain line‑breaks or trailing commas – json.load handles it.
            data = json.load(f)
        return data


    def similarity(self, a: str, b: str) -> float:
        """
        Normalised similarity (0‑1) between two strings.
        `difflib.SequenceMatcher` gives a quick, lightweight approximation.
        """
        return difflib.SequenceMatcher(None, a.lower(), b.lower()).ratio()


    def find_best_match(self, query: str, *, min_ratio: float = 0.3, ) -> Optional[Tuple[str, str, int, int]]:
        """
        Scan the whole data set and return the entry that best matches ``query``.

        Returns
        -------
        (page, word, x, y)  or  None  if nothing meets ``min_ratio``.
        """
        best: Tuple[float, Optional[Tuple[str, str, int, int]]] = (0.0, None)

        for page_obj in self.dataset:
            page_no = page_obj["page"]
            for w in page_obj["words"]:
                word = w["t"]
                # Quick pre‑filter – does the query appear as a substring?
                if query.lower() not in word.lower():
                    continue

                # Compute a similarity score; higher is better.
                score = self.similarity(query, word)

                # Keep the highest‑scoring candidate.
                if score > best[0]:
                    best = (score, (page_no, word, w["x"], w["y"]))

        # If the best score is still below the threshold we treat it as “no good match”.
        if best[0] >= min_ratio:
            return best[1]
        return None

    def build_local_url_query(self, page: str, x: int, y: int,
                        word: str, transformed: bool = True) -> str:
        base = Path(__file__).parent / "gregg_dict" / "greggpad.html"
        # Build the query string manually – urllib.parse.urlencode takes care of escaping.
        query_dict = {
            "page": f"{page}.png",
            "x": str(x),
            "y": str(y),
            "word": word,
            "transformed": str(transformed)
        }
        query = urllib.parse.urlencode(query_dict, safe="")   # safe="" → escape everything that isn’t alnum
        return f"file://{base.as_posix()}?{query}"

    def build_local_url_frag(self, page: str, x: int, y: int,
                        word: str, transformed: bool = True) -> str:
        base = Path(__file__).parent / "gregg_dict" / "greggpad.html"
        frag = urllib.parse.urlencode({
            "page": f"{page}.png",
            "x": str(x),
            "y": str(y),
            "word": word,
            "transformed": str(transformed)
        })
        return f"file://{base.as_posix()}#{frag}"

    def open_via_shell(self, url: str) -> None:
        if sys.platform.startswith("win"):
            print(f"Opening via shell on Windows: {url}")
            subprocess.run([r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", url], check=False)   # Windows
        elif sys.platform.startswith("darwin"):
            subprocess.run(["open", url], check=False)       # macOS
        else:
            subprocess.run(["xdg-open", url], check=False)   # Linux/BSD

if __name__ == "__main__":
    # Replace this path with wherever you stored the JSON snippet.
    gregg_dict = Gregg_dict()
    # Load the data once – it can be reused for many queries.

    # ------------------------------------------------------------------
    # Query examples
    # ------------------------------------------------------------------
    queries = ["yeas", "abdu", "wrathful", "zinc", "zzzzz"]
    queries = ["wreath"]

    for q in queries:
        result = gregg_dict.find_best_match(q)
        if result:
            page, word, x, y = result
            print(f'Query "{q}" → page {page}, word "{word}", coordinates ({x}, {y})')
            url = gregg_dict.build_local_url_query(page, x, y, word, transformed=True)
            print(f'Opening → {url}')          # optional: lets you see what is opened
            # webbrowser.open(url)               # <-- this actually opens the file
            gregg_dict.open_via_shell(url) 
        else:
            print(f'Query "{q}" → no sufficiently close match found.')