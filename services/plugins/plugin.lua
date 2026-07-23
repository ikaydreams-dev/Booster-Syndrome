-- Booster Syndrome Plugin System
local Plugin = {}
Plugin.__index = Plugin

function Plugin:new(name, version)
    local instance = setmetatable({}, Plugin)
    instance.name = name
    instance.version = version
    instance.hooks = {}
    instance.enabled = false
    return instance
end

function Plugin:register_hook(event, callback)
    if not self.hooks[event] then
        self.hooks[event] = {}
    end
    table.insert(self.hooks[event], callback)
end

function Plugin:trigger_hook(event, data)
    if not self.hooks[event] then
        return data
    end

    for _, callback in ipairs(self.hooks[event]) do
        data = callback(data) or data
    end

    return data
end

function Plugin:enable()
    self.enabled = true
    print(string.format("Plugin '%s' v%s enabled", self.name, self.version))
end

function Plugin:disable()
    self.enabled = false
    print(string.format("Plugin '%s' disabled", self.name))
end

-- Plugin Manager
local PluginManager = {}
PluginManager.__index = PluginManager

function PluginManager:new()
    local instance = setmetatable({}, PluginManager)
    instance.plugins = {}
    return instance
end

function PluginManager:register(plugin)
    self.plugins[plugin.name] = plugin
    print(string.format("Registered plugin: %s", plugin.name))
end

function PluginManager:get(name)
    return self.plugins[name]
end

function PluginManager:enable_all()
    for _, plugin in pairs(self.plugins) do
        plugin:enable()
    end
end

function PluginManager:trigger_global_hook(event, data)
    for _, plugin in pairs(self.plugins) do
        if plugin.enabled then
            data = plugin:trigger_hook(event, data)
        end
    end
    return data
end

-- Example plugins
local AuthPlugin = Plugin:new("auth-plugin", "1.0.0")
AuthPlugin:register_hook("before_request", function(data)
    print("Auth: Validating request")
    data.authenticated = true
    return data
end)

local LoggingPlugin = Plugin:new("logging-plugin", "1.0.0")
LoggingPlugin:register_hook("before_request", function(data)
    print(string.format("Log: Request received at %s", os.date()))
    return data
end)

LoggingPlugin:register_hook("after_request", function(data)
    print(string.format("Log: Request completed at %s", os.date()))
    return data
end)

-- Usage
local manager = PluginManager:new()
manager:register(AuthPlugin)
manager:register(LoggingPlugin)
manager:enable_all()

local request_data = { path = "/api/users", method = "GET" }
request_data = manager:trigger_global_hook("before_request", request_data)

return {
    Plugin = Plugin,
    PluginManager = PluginManager
}
