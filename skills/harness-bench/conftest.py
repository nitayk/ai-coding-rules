"""pytest conftest — adds the tool root to sys.path so tests import the modules."""
import sys
from pathlib import Path

# Make the tool modules (models, tokens, tasks, judges, aggregate, plot, runners)
# importable from tests without installing the package.
sys.path.insert(0, str(Path(__file__).parent))
