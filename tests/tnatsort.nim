#
#                    natsort tests
#        Copyright (c) 2026 Uyuz-ux
#

import std/[algorithm, unittest]
import natsort

suite "natural ordering basics":
  test "numbers sort numerically, not lexicographically":
    check naturalCmp("file2", "file10") < 0
    check naturalCmp("file10", "file2") > 0
    check naturalCmp("file2", "file2") == 0

  test "classic example: files in human order":
    let files = @["file10.txt", "file2.txt", "file1.txt", "file20.txt"]
    check naturalSorted(files) ==
      @["file1.txt", "file2.txt", "file10.txt", "file20.txt"]

  test "multi-chunk strings line up after equal numeric runs":
    check naturalCmp("a1b2", "a1b10") < 0
    check naturalCmp("a10b1", "a9b2") > 0

  test "version-like strings with dots":
    let versions = @["1.10.0", "1.9.9", "1.2.0", "1.10.0-rc1"]
    check naturalSorted(versions) ==
      @["1.2.0", "1.9.9", "1.10.0", "1.10.0-rc1"]
      # "1.10.0" is a prefix of "1.10.0-rc1", and prefixes sort first
      # (also the semver-correct order: release before pre-release).

  test "arbitrarily long numbers do not overflow":
    let big = "99999999999999999999999999"
    let bigger = "999999999999999999999999999"
    check naturalCmp(big, bigger) < 0
    check naturalCmp(bigger, "1") > 0

suite "case and zeros options":
  test "case-insensitive by default":
    check naturalCmp("apple", "Banana") < 0
    check naturalCmp("Apple", "apple") == 0

  test "case-sensitive comparison is available":
    let opts = NaturalOptions(ignoreCase: false)
    check naturalCompare("Apple", "apple", opts) < 0  # 'A' (0x41) < 'a' (0x61)
    check naturalCompare("apple", "Banana", opts) > 0

  test "leading zeros compare equal by default":
    check naturalCmp("img001", "img1") == 0
    check naturalCmp("img0100", "img100") == 0
    check naturalCmp("000", "0") == 0

  test "leading zeros can break ties deterministically":
    let opts = NaturalOptions(ignoreLeadingZeros: false)
    check naturalCompare("img1", "img01", opts) < 0
    check naturalCompare("img01", "img1", opts) > 0

  test "zero-padded names still sort before longer numbers":
    check naturalCmp("img01", "img10") < 0

suite "integration":
  test "plugs into std/algorithm sorted":
    let items = @["a10", "a2", "a1"]
    check sorted(items, naturalCmp) == @["a1", "a2", "a10"]

  test "isNaturalSorted validates lists":
    check isNaturalSorted(@["a", "b2", "b10"])
    check not isNaturalSorted(@["b10", "b2", "a"])

  test "naturalLess convenience":
    check naturalLess("episode9", "episode11")
    check not naturalLess("episode11", "episode11")

  test "empty strings and prefixes":
    check naturalCmp("", "") == 0
    check naturalCmp("", "a") < 0
    check naturalCmp("a", "a") == 0
    check naturalCmp("a", "ab") < 0

  test "mixed digits and text keep codepoint order":
    # A digit never equals a letter; digits sort by their value only
    # when both sides are digits at the same position.
    check naturalCmp("2fast", "fast") < 0  # '2' < 'f'
    check naturalCmp("v2", "v2a") < 0
