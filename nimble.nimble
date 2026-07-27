# Package
version       = "1.0.0"
author        = "Booster Team"
description   = "Multi-language microservices architecture"
license       = "MIT"
srcDir        = "services/nim"

# Dependencies
requires "nim >= 2.0.0"
requires "asyncdispatch"
requires "httpclient"
requires "json"

# Tasks
task test, "Run tests":
  exec "nim c -r tests/nim/test_all.nim"

task build, "Build the project":
  exec "nim c -d:release src/main.nim"
