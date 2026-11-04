#
#                    natsort
#        Copyright (c) 2026 Uyuz-ux
#
#      See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## Natural (human-friendly) sorting for Nim.
##
## Standard lexicographic sorting puts `"file10"` before `"file2"` and
## `"img9.png"` after `"img10.png"`, because strings are compared
## character by character. Humans expect the opposite. `natsort`
## compares embedded runs of digits as whole numbers, so lists end up
## in the order a person would put them:
##
## ```nim
## import natsort
##
## let files = @["file10.txt", "file2.txt", "file1.txt"]
## echo files.naturalSorted
## # @["file1.txt", "file2.txt", "file10.txt"]
## ```
##
## Numbers of any length are supported: digit runs are compared by
## magnitude without converting them to integers, so `"99999999999999999999"`
## is handled exactly as well as `"9"` and never overflows.
##
## See also:
## * `strutils<https://nim-lang.org/docs/strutils.html>`_ for the
##   plain lexicographic `cmp`.

import std/[algorithm, strutils]

type
  NaturalOptions* = object
    ## Tuning knobs for `naturalCmp`.
    ##
    ## * `ignoreCase` - when true (default) `A` and `a` compare equal
    ##   (ASCII case folding only; non-ASCII characters keep their
    ##   codepoint order).
    ## * `ignoreLeadingZeros` - when true (default) `img001` and `img1`
    ##   compare equal as numbers. When false, digit runs that are
    ##   numerically equal are ordered by their leading zeros, so
    ##   `img1` sorts before `img01`.
    ignoreCase*: bool
    ignoreLeadingZeros*: bool

proc defaultNaturalOptions*(): NaturalOptions =
  ## The default settings: case-insensitive, leading zeros ignored.
  ## Change single knobs like:
  ## ```nim
  ## var opts = defaultNaturalOptions()
  ## opts.ignoreCase = false
  ## ```
  NaturalOptions(ignoreCase: true, ignoreLeadingZeros: true)

proc fold(c: char, ignoreCase: bool): char =
  if ignoreCase:
    c.toLowerAscii()
  else:
    c

proc cmpDigitRun(a: string, ai: var int, b: string, bj: var int,
    options: NaturalOptions): int =
  ## Compare the digit runs starting at `ai` (in `a`) and `bj` (in `b`).
  ## Advances both indices past the runs. Returns 0 when the runs are
  ## numerically equal under `options`; otherwise an ordering result.
  ## The caller must NOT assume the indices advanced equally when 0 is
  ## returned for equal runs - they do advance equally here because
  ## both runs are fully consumed, which is what makes the following
  ## text chunks line up again.
  let startI = ai
  let startJ = bj
  while ai < a.len and a[ai].isDigit: inc ai
  while bj < b.len and b[bj].isDigit: inc bj

  var numA = a[startI ..< ai]
  var numB = b[startJ ..< bj]

  # Magnitude comparison without integers: strip leading zeros, then
  # longer is bigger, then lexicographic (digits only, same length).
  var za = 0
  while za < numA.len and numA[za] == '0': inc za
  var zb = 0
  while zb < numB.len and numB[zb] == '0': inc zb
  let sigA = numA.substr(za)
  let sigB = numB.substr(zb)

  if sigA.len != sigB.len:
    return cmp(sigA.len, sigB.len)
  if sigA != sigB:
    return cmp(sigA, sigB)

  # Numerically equal. Either ignore the zeros, or order by them.
  if options.ignoreLeadingZeros:
    return 0
  return cmp(za, zb)

proc naturalCompareImpl(a, b: string, options: NaturalOptions): int =
  ## Compare `a` and `b` the way a human would.
  ##
  ## Returns a value less than, equal to, or greater than 0, just like
  ## `system.cmp`, so it plugs directly into `sort`, `sorted` and
  ## `algorithm.sortedByIt`:
  ##
  ## ```nim
  ## import std/[algorithm], natsort
  ## echo sorted(@["a10", "a2"], naturalCmp)  # @["a2", "a10"]
  ## ```
  ##
  ## Rules:
  ## * Runs of ASCII digits are compared as whole numbers of arbitrary
  ##   length, not character by character.
  ## * Everything else is compared as text (ASCII case folding when
  ##   `options.ignoreCase`).
  ## * A digit run and a text chunk never compare "equal"; digits
  ##   compare by their numeric order, text by its codepoint order.
  ## * When two digit runs are numerically equal and
  ##   `options.ignoreLeadingZeros` is true, the next chunks decide.
  var i = 0
  var j = 0
  while i < a.len and j < b.len:
    let ca = a[i]
    let cb = b[j]
    if ca.isDigit and cb.isDigit:
      let r = cmpDigitRun(a, i, b, j, options)
      if r != 0:
        return r
      # Equal numeric runs: continue with what follows them.
    else:
      let fa = fold(ca, options.ignoreCase)
      let fb = fold(cb, options.ignoreCase)
      if fa != fb:
        return cmp(fa, fb)
      inc i
      inc j
  # Whatever string still has characters left sorts later; equal
  # remainders (both empty) compare equal.
  result = cmp(a.len - i, b.len - j)

proc naturalCmp*(a, b: string): int =
  ## Compare `a` and `b` the way a human would, with default options.
  ##
  ## Returns a value less than, equal to, or greater than 0, just like
  ## `system.cmp`, so it is directly usable as a comparator:
  ##
  ## ```nim
  ## import std/[algorithm], natsort
  ## echo sorted(@["a10", "a2"], naturalCmp)  # @["a2", "a10"]
  ## ```
  ##
  ## Rules:
  ## * Runs of ASCII digits are compared as whole numbers of arbitrary
  ##   length, not character by character.
  ## * Everything else is compared as text with ASCII case folding.
  ## * A digit run and a text chunk never compare "equal"; digits
  ##   compare by their numeric order, text by its codepoint order.
  ##
  ## For custom behavior (case sensitivity, leading zeros) see
  ## `naturalCompare` and `NaturalOptions`.
  naturalCompareImpl(a, b, defaultNaturalOptions())

proc naturalCompare*(a, b: string, options: NaturalOptions): int {.inline.} =
  ## `naturalCmp` with custom `NaturalOptions`.
  naturalCompareImpl(a, b, options)

proc naturalLess*(a, b: string, options = defaultNaturalOptions()): bool {.inline.} =
  ## Convenience predicate: the pair sorts in natural order
  ## (`naturalCompare(a, b, options) < 0`).
  naturalCompareImpl(a, b, options) < 0

proc naturalSorted*(items: openArray[string],
    options = defaultNaturalOptions()): seq[string] =
  ## Return a new sequence with `items` sorted in natural order.
  ##
  ## ```nim
  ## import natsort
  ## echo naturalSorted(@["v1.9", "v1.10", "v1.2"])
  ## # @["v1.2", "v1.9", "v1.10"]
  ## ```
  result = @items
  result.sort do (x, y: string) -> int:
    naturalCompareImpl(x, y, options)

proc naturalSort*(items: var seq[string],
    options = defaultNaturalOptions()): seq[string] {.discardable.} =
  ## Sort `items` in place in natural order and return them, so the call
  ## can be chained. Use this instead of `naturalSorted` when you already
  ## own the sequence and do not need to keep the original order.
  ##
  ## ```nim
  ## import natsort
  ## var files = @["file10.txt", "file2.txt"]
  ## files.naturalSort()
  ## # files is now @["file2.txt", "file10.txt"]
  ## ```
  items.sort do (x, y: string) -> int:
    naturalCompareImpl(x, y, options)
  result = items

proc isNaturalSorted*(items: openArray[string],
    options = defaultNaturalOptions()): bool =
  ## Check whether `items` is already in natural order (useful in tests
  ## and assertions).
  for k in 1 ..< items.len:
    if naturalCompareImpl(items[k - 1], items[k], options) > 0:
      return false
  result = true
