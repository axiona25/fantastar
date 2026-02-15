import sys
from pathlib import Path

import pytest

# Carica .env dalla root progetto se presente
_backend = Path(__file__).resolve().parent.parent
_root = _backend.parent
_env = _root / ".env"
if _env.exists():
    from dotenv import load_dotenv
    load_dotenv(_env)

sys.path.insert(0, str(_backend))

pytest_plugins = ["pytest_asyncio"]


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"
