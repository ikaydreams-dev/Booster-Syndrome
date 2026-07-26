const std = @import("std");

pub fn sum(comptime T: type, items: []const T) T {
    var total: T = 0;
    for (items) |item| {
        total += item;
    }
    return total;
}

pub fn max(comptime T: type, items: []const T) ?T {
    if (items.len == 0) return null;
    
    var maximum = items[0];
    for (items[1..]) |item| {
        if (item > maximum) {
            maximum = item;
        }
    }
    return maximum;
}

pub fn min(comptime T: type, items: []const T) ?T {
    if (items.len == 0) return null;
    
    var minimum = items[0];
    for (items[1..]) |item| {
        if (item < minimum) {
            minimum = item;
        }
    }
    return minimum;
}

pub fn reverse(comptime T: type, items: []T) void {
    var i: usize = 0;
    var j: usize = items.len - 1;
    
    while (i < j) {
        const temp = items[i];
        items[i] = items[j];
        items[j] = temp;
        i += 1;
        j -= 1;
    }
}

pub fn contains(comptime T: type, items: []const T, value: T) bool {
    for (items) |item| {
        if (item == value) {
            return true;
        }
    }
    return false;
}

pub fn indexOf(comptime T: type, items: []const T, value: T) ?usize {
    for (items, 0..) |item, i| {
        if (item == value) {
            return i;
        }
    }
    return null;
}

pub fn filter(comptime T: type, allocator: std.mem.Allocator, items: []const T, predicate: fn(T) bool) ![]T {
    var result = std.ArrayList(T).init(allocator);
    defer result.deinit();
    
    for (items) |item| {
        if (predicate(item)) {
            try result.append(item);
        }
    }
    
    return result.toOwnedSlice();
}

pub fn map(comptime T: type, comptime R: type, allocator: std.mem.Allocator, items: []const T, mapper: fn(T) R) ![]R {
    var result = std.ArrayList(R).init(allocator);
    defer result.deinit();
    
    for (items) |item| {
        try result.append(mapper(item));
    }
    
    return result.toOwnedSlice();
}
