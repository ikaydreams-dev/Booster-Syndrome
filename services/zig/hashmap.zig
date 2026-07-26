const std = @import("std");

pub fn HashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Entry = struct {
            key: K,
            value: V,
        };
        
        allocator: std.mem.Allocator,
        entries: std.ArrayList(?Entry),
        size: usize,
        
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .entries = std.ArrayList(?Entry).init(allocator),
                .size = 0,
            };
        }
        
        pub fn deinit(self: *Self) void {
            self.entries.deinit();
        }
        
        fn hash(key: K) usize {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key);
            return hasher.final();
        }
        
        pub fn put(self: *Self, key: K, value: V) !void {
            const h = hash(key) % self.entries.items.len;
            self.entries.items[h] = Entry{ .key = key, .value = value };
            self.size += 1;
        }
        
        pub fn get(self: *Self, key: K) ?V {
            if (self.entries.items.len == 0) return null;
            
            const h = hash(key) % self.entries.items.len;
            if (self.entries.items[h]) |entry| {
                if (entry.key == key) {
                    return entry.value;
                }
            }
            return null;
        }
        
        pub fn remove(self: *Self, key: K) bool {
            if (self.entries.items.len == 0) return false;
            
            const h = hash(key) % self.entries.items.len;
            if (self.entries.items[h]) |entry| {
                if (entry.key == key) {
                    self.entries.items[h] = null;
                    self.size -= 1;
                    return true;
                }
            }
            return false;
        }
        
        pub fn contains(self: *Self, key: K) bool {
            return self.get(key) != null;
        }
        
        pub fn clear(self: *Self) void {
            for (self.entries.items) |*entry| {
                entry.* = null;
            }
            self.size = 0;
        }
    };
}
