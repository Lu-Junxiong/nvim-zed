"""Return a bounded Polars sample for the editor's read-only preview."""
import json
import sys
from pathlib import Path

ROWS = 50
COLUMNS = 20
CELL_CHARS = 160


def text(value):
    if value is None:
        return "null"
    value = str(value).replace("\r", "\\r").replace("\n", "\\n").replace("\t", "\\t")
    return value[:CELL_CHARS] + ("…" if len(value) > CELL_CHARS else "")


def preview(path):
    import polars as pl

    suffix = path.suffix.lower()
    if suffix == ".parquet":
        frame = pl.scan_parquet(path, n_rows=ROWS, glob=False, hive_partitioning=False)
    elif suffix in (".csv", ".tsv"):
        frame = pl.scan_csv(path, separator="\t" if suffix == ".tsv" else ",",
                            n_rows=ROWS, infer_schema_length=ROWS, glob=False)
    else:
        raise ValueError("Supported formats: CSV, TSV, Parquet")
    schema = frame.collect_schema()
    names = schema.names()[:COLUMNS]
    sample = frame.select(names).head(ROWS).collect()
    return {"columns": [{"name": text(name), "type": text(schema[name])} for name in names],
            "total_columns": len(schema), "rows": [[text(cell) for cell in row] for row in sample.rows()],
            "row_limit": ROWS, "column_limit": COLUMNS}


if __name__ == "__main__":
    try:
        import polars as pl
    except ImportError as error:
        sys.exit("Polars is required in the selected Python environment: " + str(error))
    try:
        result = preview(Path(sys.argv[1]))
    except (OSError, ValueError, pl.exceptions.PolarsError) as error:
        sys.exit(str(error)[:2000])
    print(json.dumps(result, ensure_ascii=False))
