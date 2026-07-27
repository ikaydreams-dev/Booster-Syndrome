switch("path", "$projectDir/services/nim")
switch("nimcache", ".nimcache")

when defined(release):
  switch("opt", "speed")
  switch("define", "release")
else:
  switch("debugger", "native")
  switch("define", "debug")

task test, "Run tests":
  exec "nim c -r tests/nim/test_all.nim"

task clean, "Clean build artifacts":
  exec "rm -rf .nimcache"
