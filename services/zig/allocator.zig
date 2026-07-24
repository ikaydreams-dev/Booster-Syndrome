const std = @import("std");

pub const ArenaAllocator = struct {
    buffer: []u8,
    offset: usize,

    pub fn init(buffer: []u8) ArenaAllocator {
        return ArenaAllocator{
            .buffer = buffer,
            .offset = 0,
        };
    }

    pub fn alloc(self: *ArenaAllocator, size: usize) ![]u8 {
        if (self.offset + size > self.buffer.len) {
            return error.OutOfMemory;
        }

        const result = self.buffer[self.offset .. self.offset + size];
        self.offset += size;
        return result;
    }

    pub fn reset(self: *ArenaAllocator) void {
        self.offset = 0;
    }
};

pub const PoolAllocator = struct {
    buffer: []u8,
    block_size: usize,
    free_list: ?*FreeNode,

    const FreeNode = struct {
        next: ?*FreeNode,
    };

    pub fn init(buffer: []u8, block_size: usize) PoolAllocator {
        var allocator = PoolAllocator{
            .buffer = buffer,
            .block_size = block_size,
            .free_list = null,
        };

        var i: usize = 0;
        while (i + block_size <= buffer.len) : (i += block_size) {
            const node = @ptrCast(*FreeNode, @alignCast(@alignOf(FreeNode), &buffer[i]));
            node.next = allocator.free_list;
            allocator.free_list = node;
        }

        return allocator;
    }

    pub fn alloc(self: *PoolAllocator) ![]u8 {
        const node = self.free_list orelse return error.OutOfMemory;
        self.free_list = node.next;

        const ptr = @ptrCast([*]u8, node);
        return ptr[0..self.block_size];
    }

    pub fn free(self: *PoolAllocator, ptr: []u8) void {
        const node = @ptrCast(*FreeNode, @alignCast(@alignOf(FreeNode), ptr.ptr));
        node.next = self.free_list;
        self.free_list = node;
    }
};

pub fn swap(comptime T: type, a: *T, b: *T) void {
    const temp = a.*;
    a.* = b.*;
    b.* = temp;
}

pub fn sort(comptime T: type, items: []T) void {
    if (items.len <= 1) return;

    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and items[j - 1] > items[j]) : (j -= 1) {
            swap(T, &items[j - 1], &items[j]);
        }
    }
}

pub fn binarySearch(comptime T: type, items: []const T, target: T) ?usize {
    var left: usize = 0;
    var right: usize = items.len;

    while (left < right) {
        const mid = left + (right - left) / 2;

        if (items[mid] == target) {
            return mid;
        } else if (items[mid] < target) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }

    return null;
}

pub fn HashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Entry = struct {
            key: K,
            value: V,
            next: ?*Entry,
        };

        buckets: []?*Entry,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            const buckets = try allocator.alloc(?*Entry, capacity);
            for (buckets) |*bucket| {
                bucket.* = null;
            }

            return Self{
                .buckets = buckets,
                .allocator = allocator,
            };
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            const index = hash(key) % self.buckets.len;
            const entry = try self.allocator.create(Entry);
            entry.* = Entry{
                .key = key,
                .value = value,
                .next = self.buckets[index],
            };
            self.buckets[index] = entry;
        }

        pub fn get(self: *Self, key: K) ?V {
            const index = hash(key) % self.buckets.len;
            var current = self.buckets[index];

            while (current) |entry| {
                if (entry.key == key) {
                    return entry.value;
                }
                current = entry.next;
            }

            return null;
        }

        fn hash(key: K) usize {
            return @intCast(usize, key);
        }
    };
}
