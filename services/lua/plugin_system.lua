-- Plugin System for Lua

local PluginManager = {}
PluginManager.__index = PluginManager

function PluginManager:new()
    local instance = {
        plugins = {},
        hooks = {},
        loaded = {}
    }
    setmetatable(instance, PluginManager)
    return instance
end

function PluginManager:register(name, plugin)
    self.plugins[name] = plugin
end

function PluginManager:load(name)
    if self.loaded[name] then
        return true
    end

    local plugin = self.plugins[name]
    if not plugin then
        return false, "Plugin not found: " .. name
    end

    if plugin.init then
        local success, err = pcall(plugin.init)
        if not success then
            return false, "Plugin init failed: " .. err
        end
    end

    self.loaded[name] = true
    return true
end

function PluginManager:unload(name)
    if not self.loaded[name] then
        return false
    end

    local plugin = self.plugins[name]
    if plugin and plugin.cleanup then
        pcall(plugin.cleanup)
    end

    self.loaded[name] = nil
    return true
end

function PluginManager:registerHook(name, callback)
    if not self.hooks[name] then
        self.hooks[name] = {}
    end
    table.insert(self.hooks[name], callback)
end

function PluginManager:executeHook(name, ...)
    if not self.hooks[name] then
        return
    end

    for _, callback in ipairs(self.hooks[name]) do
        pcall(callback, ...)
    end
end

function PluginManager:listPlugins()
    local list = {}
    for name, _ in pairs(self.plugins) do
        table.insert(list, {
            name = name,
            loaded = self.loaded[name] or false
        })
    end
    return list
end

-- Event System

local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter:new()
    local instance = {
        listeners = {}
    }
    setmetatable(instance, EventEmitter)
    return instance
end

function EventEmitter:on(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], callback)
end

function EventEmitter:once(event, callback)
    local wrapper
    wrapper = function(...)
        callback(...)
        self:off(event, wrapper)
    end
    self:on(event, wrapper)
end

function EventEmitter:off(event, callback)
    if not self.listeners[event] then
        return
    end

    for i, cb in ipairs(self.listeners[event]) do
        if cb == callback then
            table.remove(self.listeners[event], i)
            break
        end
    end
end

function EventEmitter:emit(event, ...)
    if not self.listeners[event] then
        return
    end

    for _, callback in ipairs(self.listeners[event]) do
        callback(...)
    end
end

-- Module System

local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

function ModuleLoader:new()
    local instance = {
        modules = {},
        cache = {}
    }
    setmetatable(instance, ModuleLoader)
    return instance
end

function ModuleLoader:define(name, factory)
    self.modules[name] = factory
end

function ModuleLoader:require(name)
    if self.cache[name] then
        return self.cache[name]
    end

    local factory = self.modules[name]
    if not factory then
        error("Module not found: " .. name)
    end

    local module = factory()
    self.cache[name] = module
    return module
end

function ModuleLoader:clear(name)
    if name then
        self.cache[name] = nil
    else
        self.cache = {}
    end
end

-- Config System

local Config = {}
Config.__index = Config

function Config:new()
    local instance = {
        data = {}
    }
    setmetatable(instance, Config)
    return instance
end

function Config:set(key, value)
    self.data[key] = value
end

function Config:get(key, default)
    local value = self.data[key]
    if value == nil then
        return default
    end
    return value
end

function Config:has(key)
    return self.data[key] ~= nil
end

function Config:remove(key)
    self.data[key] = nil
end

function Config:merge(other)
    for k, v in pairs(other) do
        self.data[k] = v
    end
end

function Config:all()
    local copy = {}
    for k, v in pairs(self.data) do
        copy[k] = v
    end
    return copy
end

-- State Machine

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new(initial)
    local instance = {
        current = initial,
        states = {},
        transitions = {}
    }
    setmetatable(instance, StateMachine)
    return instance
end

function StateMachine:addState(name, onEnter, onExit)
    self.states[name] = {
        onEnter = onEnter,
        onExit = onExit
    }
end

function StateMachine:addTransition(from, to, event)
    local key = from .. ":" .. event
    self.transitions[key] = to
end

function StateMachine:trigger(event)
    local key = self.current .. ":" .. event
    local nextState = self.transitions[key]

    if not nextState then
        return false, "Invalid transition"
    end

    local currentState = self.states[self.current]
    if currentState and currentState.onExit then
        currentState.onExit()
    end

    self.current = nextState

    local newState = self.states[nextState]
    if newState and newState.onEnter then
        newState.onEnter()
    end

    return true
end

function StateMachine:getState()
    return self.current
end

return {
    PluginManager = PluginManager,
    EventEmitter = EventEmitter,
    ModuleLoader = ModuleLoader,
    Config = Config,
    StateMachine = StateMachine
}
