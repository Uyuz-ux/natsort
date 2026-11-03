# natsort

Natural (human-friendly) sorting for Nim.

Plain lexicographic sorting compares strings character by character, so
`"file10"` ends up before `"file2"` and `"img9.png"` after `"img10.png"`.
**natsort** compares embedded runs of digits as whole numbers, so lists
come out in the order a human would put them:

```nim
import natsort

echo naturalSorted(@["file10.txt", "file2.txt", "file1.txt"])
# @["file1.txt", "file2.txt", "file10.txt"]
```

## Highlights

* **Plugs into the stdlib** — `naturalCmp` is a drop-in comparator for
  `sorted`, `sort` and friends:

  ```nim
  import std/[algorithm], natsort
  echo sorted(@["a10", "a2"], naturalCmp)  # @["a2", "a10"]
  ```

* **Arbitrary-length numbers** — digit runs are compared by magnitude
  without converting to integers, so `"99999999999999999999"` works
  exactly as well as `"9"` and nothing overflows.

* **Tunable** — `naturalCompare(a, b, options)` lets you turn case
  folding and leading-zero handling on or off:

  ```nim
  var opts = NaturalOptions(ignoreCase: false)
  echo naturalCompare("Apple", "apple", opts)  # < 0, 'A' before 'a'
  ```

* **Zero-config checks** — `naturalLess(a, b)` for quick predicates and
  `isNaturalSorted(items)` for assertions.

| Input | Lexicographic sort | natsort |
|---|---|---|
| `file1, file10, file2` | `file1, file10, file2` | `file1, file2, file10` |
| `img1, img01, img2` | `img01, img1, img2` | `img1, img01, img2` (equal numbers keep list order) |
| `v1.2, v1.10, v1.9` | `v1.10, v1.2, v1.9` | `v1.2, v1.9, v1.10` |

## Comparison rules

1. Runs of ASCII digits are compared as whole numbers.
2. When two digit runs are numerically equal, the surrounding text
   decides (`img001` equals `img1` by default; pass
   `NaturalOptions(ignoreLeadingZeros: false)` to order them by their
   zeros).
3. All other characters compare by codepoint, with ASCII case folding
   by default (`ignoreCase: false` disables it). Non-ASCII (UTF-8)
   characters keep their codepoint order; locale-specific collation is
   out of scope.

## Installation

```
nimble install natsort
```

*(listed in the Nimble package index; you can also add it as a
dependency directly from the repository)*

## Running the tests

```
nimble test
```

## License

MIT — see [LICENSE](LICENSE).
