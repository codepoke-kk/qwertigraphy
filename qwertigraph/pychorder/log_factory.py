
import logging
import logging.handlers
import os
from pathlib import Path

_LOGGER_NAME = "qw"
_logger = None

def _build_root_logger() -> logging.Logger:
    """Create the root logger that writes to STDOUT and a rotating file."""
    logger = logging.getLogger(_LOGGER_NAME)
    logger.setLevel(logging.DEBUG)                # accept everything; filters later

    # ---- Handlers ------------------------------------------------
    # 1️⃣ Console (STDOUT)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)      # let per‑class filter decide

    # 2️⃣ Rotating file (10 MiB per file, keep 5 backups)
    log_dir = Path(os.getenv("LOG_DIR", "logs"))
    log_dir.mkdir(parents=True, exist_ok=True)
    file_path = log_dir / os.getenv("LOG_FILE", "app.log")
    file_handler = logging.handlers.RotatingFileHandler(
        file_path,
        maxBytes=10 * 1024 * 1024,
        backupCount=5,
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
    env_key = f"LOG_LEVEL_{class_abbr.upper()}"
    level_name = os.getenv(env_key, "INFO").upper()
    print(f"Setting log level for {class_abbr} to {env_key} as {level_name}")
    level = getattr(logging, level_name, logging.INFO)

    # Create a child logger so we can set a per‑class level without affecting others.
    child_logger = logging.getLogger(f"{_LOGGER_NAME}.{class_abbr}")
    child_logger.setLevel(level)

    # The LoggerAdapter adds the extra ``prefix`` attribute used by the formatter.
    return logging.LoggerAdapter(child_logger, {"prefix": class_abbr})

