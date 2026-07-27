package = "booster"
version = "1.0-1"
source = {
   url = "git://github.com/ikaydreams-dev/Booster-Syndrome.git",
   tag = "v1.0"
}
description = {
   summary = "Booster Syndrome Multi-Language Utilities",
   detailed = [[
      Lua utilities for the Booster Syndrome microservices platform.
   ]],
   homepage = "https://github.com/ikaydreams-dev/Booster-Syndrome",
   license = "MIT"
}
dependencies = {
   "lua >= 5.3"
}
build = {
   type = "builtin",
   modules = {
      ["booster.table_utils"] = "services/lua/table_utils.lua",
      ["booster.string_utils"] = "services/lua/string_utils.lua"
   }
}
