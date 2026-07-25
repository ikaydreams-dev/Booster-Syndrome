-- Table utility functions

local M = {}

-- Map function
function M.map(tbl, func)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = func(v)
    end
    return result
end

-- Filter function
function M.filter(tbl, predicate)
    local result = {}
    for i, v in ipairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

-- Reduce function
function M.reduce(tbl, func, initial)
    local acc = initial
    for i, v in ipairs(tbl) do
        acc = func(acc, v)
    end
    return acc
end

-- Find function
function M.find(tbl, predicate)
    for i, v in ipairs(tbl) do
        if predicate(v) then
            return v, i
        end
    end
    return nil, nil
end

-- Contains function
function M.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Merge tables
function M.merge(...)
    local result = {}
    for _, tbl in ipairs({...}) do
        for k, v in pairs(tbl) do
            result[k] = v
        end
    end
    return result
end

-- Deep copy
function M.deep_copy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    
    local result = {}
    for k, v in pairs(tbl) do
        result[M.deep_copy(k)] = M.deep_copy(v)
    end
    
    return setmetatable(result, getmetatable(tbl))
end

-- Table size
function M.size(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Reverse array
function M.reverse(tbl)
    local result = {}
    for i = #tbl, 1, -1 do
        table.insert(result, tbl[i])
    end
    return result
end

-- Unique values
function M.unique(tbl)
    local seen = {}
    local result = {}
    for _, v in ipairs(tbl) do
        if not seen[v] then
            seen[v] = true
            table.insert(result, v)
        end
    end
    return result
end

return M
