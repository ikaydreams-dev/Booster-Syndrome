-- String utility functions

local M = {}

-- Split string by delimiter
function M.split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    
    return result
end

-- Trim whitespace
function M.trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

-- Starts with
function M.starts_with(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

-- Ends with
function M.ends_with(str, suffix)
    return string.sub(str, -#suffix) == suffix
end

-- Contains
function M.contains(str, substring)
    return string.find(str, substring, 1, true) ~= nil
end

-- Capitalize first letter
function M.capitalize(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

-- To snake_case
function M.to_snake_case(str)
    return string.gsub(str, "(%u)", function(c)
        return "_" .. string.lower(c)
    end):sub(2)
end

-- To camelCase
function M.to_camel_case(str)
    return string.gsub(str, "_(%w)", function(c)
        return string.upper(c)
    end)
end

-- Repeat string
function M.repeat_str(str, count)
    return string.rep(str, count)
end

-- Reverse string
function M.reverse(str)
    return string.reverse(str)
end

-- Count occurrences
function M.count(str, substring)
    local _, count = string.gsub(str, substring, "")
    return count
end

-- Pad left
function M.pad_left(str, length, char)
    char = char or " "
    return string.rep(char, length - #str) .. str
end

-- Pad right
function M.pad_right(str, length, char)
    char = char or " "
    return str .. string.rep(char, length - #str)
end

return M
