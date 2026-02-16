
import logging
import logging.handlers
import os
from pathlib import Path
from typing import Dict, List, Any
import json

_LOGGER_NAME = "qw"
_logger = None

CONFIG_DIR = Path(os.getenv("APPDATA", "")) / "Qwertigraph"
CONFIG_FILE = CONFIG_DIR / "qw.config"

def ensure_config_dir() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

def load_config() -> Dict[str, Any]:
    """
    Load the JSON configuration file and return a dict.
    If the file does not exist or cannot be parsed, an empty dict is returned.
    """
    ensure_config_dir()
    # print("Loading config")

    if not CONFIG_FILE.is_file():
        print("Config file missing - returning empty dict")
        return {}

    try:
        data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            print.warning("Config file did not contain a JSON object - resetting")
            return {}
        
        # Make sure we have some dictionaries. 
        if "dict_sources" not in data or not isinstance(data["dict_sources"], list) or not (len(data["dict_sources"])):
            data["dict_sources"] = [
                "%AppData%/Qwertigraph/personal.csv",
                "dictionaries/anniversary_required.csv",
                "dictionaries/anniversary_uniform_supplement.csv",
                "dictionaries/anniversary_uniform_core.csv",
                "dictionaries/anniversary_modern.csv",
                "dictionaries/anniversary_cmu.csv"
            ]
        
        # print(f"Config loaded: keys={list(data.keys())}")
        return data
    except Exception as exc:            # pragma: no cover – defensive logging
        print(f"Could not read config: {exc}")
        return {}

def _build_root_logger() -> logging.Logger:
    """Create the root logger that writes to STDOUT and a rotating file."""
    logger = logging.getLogger(_LOGGER_NAME)
    logger.setLevel(logging.DEBUG)                # accept everything; filters later

    # ---- Handlers ------------------------------------------------
    # 1️ Console (STDOUT)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)      # let per‑class filter decide

    # 2 Rotating file (10 MiB per file, keep 5 backups)
    # log_dir = Path(os.getenv("LOG_DIR", "logs"))
    log_dir = Path("c:\\Windows\\temp\\qwertigraph")
    log_dir.mkdir(parents=True, exist_ok=True)
    file_path = log_dir / os.getenv("LOG_FILE", "app.log")
    file_handler = logging.handlers.RotatingFileHandler(
        file_path,
        maxBytes=50 * 1024 * 1024,
        backupCount=0,
        encoding="utf-8",
    )
    file_handler.setLevel(logging.DEBUG)

    # ---- Formatter ------------------------------------------------
    # Format: 2025-09-06 12:34:56,789 | LEVEL | PREFIX | message
    fmt = "%(asctime)s | %(levelname)-8s | %(prefix)-6s | %(message)s"
    datefmt = "%Y-%m-%d %H:%M:%S"
    formatter = logging.Formatter(fmt, datefmt=datefmt)

    console_handler.setFormatter(formatter)
    file_handler.setFormatter(formatter)

    # ---- Attach ---------------------------------------------------
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)

    # Avoid duplicate propagation to the root logger
    logger.propagate = False
    return logger


def get_logger(class_abbr: str) -> logging.LoggerAdapter:
    """
    Return a LoggerAdapter that injects ``prefix`` (the class abbreviation)
    into every LogRecord.  The adapter behaves exactly like a normal logger.
    """
    global _logger
    if _logger is None:
        _logger = _build_root_logger()

    # Pull the desired level for this class from the environment.
    # Expected env var: LOG_LEVEL_<ABBR>, e.g. LOG_LEVEL_DB=DEBUG

    cfg = load_config() 
    # print(f"Config for {class_abbr}: {cfg.get(f'LOG_LEVEL_{class_abbr}', 'INFO')} set")
    env_key = f"LOG_LEVEL_{class_abbr.upper()}"
    # level_name = os.getenv(env_key, "INFO").upper()
    level_name = cfg.get(env_key, 'INFO')
    print(f"Setting log level for {class_abbr} to {env_key} as {level_name}")
    level = getattr(logging, level_name, logging.INFO)

    # Create a child logger so we can set a per‑class level without affecting others.
    child_logger = logging.getLogger(f"{_LOGGER_NAME}.{class_abbr}")
    child_logger.setLevel(level)

    # The LoggerAdapter adds the extra ``prefix`` attribute used by the formatter.
    return logging.LoggerAdapter(child_logger, {"prefix": class_abbr})

