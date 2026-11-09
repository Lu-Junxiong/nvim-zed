"""Exercise preview limits and formats with real Polars files."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

import polars as pl

spec = importlib.util.spec_from_file_location("preview", Path(__file__).parents[1] / "tools/preview.py")
preview = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preview)


class PreviewTests(unittest.TestCase):
    def test_csv_parquet_and_tsv(self):
        with tempfile.TemporaryDirectory() as directory:
            frame = pl.DataFrame({"name": ["a,b\n第二行", None], "value": [1, 2]})
            for suffix in (".csv", ".parquet", ".tsv"):
                with self.subTest(suffix=suffix):
                    path = Path(directory) / ('sample [a]* | "' + suffix)
                    if suffix == ".parquet":
                        frame.write_parquet(path)
                    else:
                        frame.write_csv(path, separator="\t" if suffix == ".tsv" else ",")
                    before = path.read_bytes()
                    result = preview.preview(path)
                    self.assertEqual(result["rows"], [["a,b\\n第二行", "1"], ["null", "2"]])
                    self.assertEqual(result["columns"][1], {"name": "value", "type": "Int64"})
                    self.assertEqual(path.read_bytes(), before)

    def test_sample_limits_and_cell_truncation(self):
        with tempfile.TemporaryDirectory() as directory:
            frame = pl.DataFrame({"c" + str(i): ["x" * 500] * 200 for i in range(25)})
            for suffix in (".csv", ".parquet"):
                path = Path(directory) / ("wide" + suffix)
                if suffix == ".parquet":
                    frame.write_parquet(path, row_group_size=80)
                else:
                    frame.write_csv(path)
                result = preview.preview(path)
                self.assertEqual(len(result["rows"]), 50)
                self.assertEqual(len(result["columns"]), 20)
                self.assertEqual(result["total_columns"], 25)
                self.assertEqual(result["rows"][0][0], "x" * 160 + "…")

    def test_invalid_parquet_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bad.parquet"
            path.write_text("invalid")
            with self.assertRaises(pl.exceptions.PolarsError):
                preview.preview(path)


if __name__ == "__main__":
    unittest.main()
