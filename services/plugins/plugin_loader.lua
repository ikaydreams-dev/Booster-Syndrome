-- Plugin System for Booster
local PluginLoader = {}
PluginLoader.__index = PluginLoader

function PluginLoader:new()
    local instance = {
        plugins = {},
        hooks = {},
    }
    setmetatable(instance, PluginLoader)
    return instance
end

function PluginLoader:register(name, plugin)
    if self.plugins[name] then
        error("Plugin " .. name .. " already registered")
    end

    self.plugins[name] = plugin

    if plugin.init then
        plugin:init()
    end

    print("Plugin registered: " .. name)
end

function PluginLoader:get(name)
    return self.plugins[name]
end

function PluginLoader:unregister(name)
    local plugin = self.plugins[name]

    if plugin and plugin.cleanup then
        plugin:cleanup()
    end

    self.plugins[name] = nil
    print("Plugin unregistered: " .. name)
end

function PluginLoader:register_hook(hook_name, callback)
    if not self.hooks[hook_name] then
        self.hooks[hook_name] = {}
    end

    table.insert(self.hooks[hook_name], callback)
end

function PluginLoader:execute_hook(hook_name, ...)
    local hooks = self.hooks[hook_name]

    if not hooks then
        return
    end

    for _, callback in ipairs(hooks) do
        callback(...)
    end
end

function PluginLoader:list_plugins()
    local names = {}
    for name, _ in pairs(self.plugins) do
        table.insert(names, name)
    end
    return names
end

-- Example Plugin
local ExamplePlugin = {}
ExamplePlugin.__index = ExamplePlugin

function ExamplePlugin:new()
    local instance = {
        name = "Example Plugin",
        version = "1.0.0"
    }
    setmetatable(instance, ExamplePlugin)
    return instance
end

function ExamplePlugin:init()
    print("Example plugin initialized")
end

function ExamplePlugin:execute(data)
    print("Processing data: " .. tostring(data))
    return data
end

function ExamplePlugin:cleanup()
    print("Example plugin cleaned up")
end

return {
    PluginLoader = PluginLoader,
    ExamplePlugin = ExamplePlugin
}
