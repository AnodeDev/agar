const std = @import("std");
const terminal_mod = @import("terminal.zig");

const Terminal = terminal_mod.Terminal;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Data Leaked");
    }
    var tty = try Terminal.init(allocator);
    defer tty.deinit(allocator);

    try tty.enterRawMode();

    try tty.backend.clear();
    try tty.backend.write("Hello, World!");
}
