std = "lua53"
max_line_length = false

ignore = {
    "212", -- Unused argument
    "213", -- Unused loop variable
}

globals = {
    "vim",
}

read_globals = {
    "table",
    "string",
    "math",
    "os",
    "io",
}

exclude_files = {
    ".luarocks",
    "lua_modules",
}
