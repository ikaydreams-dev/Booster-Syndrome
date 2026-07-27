const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Booster Syndrome - Multi-language Microservices\n", .{});
    try stdout.print("Version: 1.0.0\n", .{});
}
