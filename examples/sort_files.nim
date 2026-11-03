## Sort file names, version strings and logs the way humans expect.
import std/[algorithm]
import natsort

let names = @["report-2026-10-01.md", "report-2026-9-15.md",
              "report-2026-10-9.md", "backup.zip", "data-2.csv",
              "data-10.csv", "data-1.csv"]

echo "Lexicographic (std sort):"
for n in names.sorted:
  echo "  ", n

echo "Natural (natsort):"
for n in naturalSorted(names):
  echo "  ", n
