# Package

version       = "0.2.0"
author        = "Uyuz-ux"
description   = "Natural (human-friendly) sorting: 'file2' before 'file10'"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6"

# Tests

task test, "Runs the test suite":
  exec "nim c -r --path:src tests/tnatsort.nim"
