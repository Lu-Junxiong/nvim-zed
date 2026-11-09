"""Run the bundled monitor without importing project packages."""
import runpy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "nvitop"))
sys.argv[0] = "nvitop"
runpy.run_module("nvitop", run_name="__main__")
