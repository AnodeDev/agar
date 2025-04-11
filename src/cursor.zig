const std = @import("std");
const terminal_mod = @import("terminal.zig");

const Terminal = terminal_mod.Terminal;

pub const Cursor = struct {
    terminal: *Terminal,
    stdout: std.fs.File,
    row: usize,
    col: usize,

    pub fn init(terminal: *Terminal) Cursor {
        const stdout = std.io.getStdOut();

        return Cursor{
            .terminal = terminal,
            .stdout = stdout,
            .row = 0,
            .col = 0,
        };
    }

    // Brings the cursor back to (0, 0)
    pub fn reset(self: *Cursor) !void {
        try self.stdout.writer().writeAll("\x1b[H");
        try self.updatePosition();
    }

    // TODO: Add boundary checks to make sure the cursor isn't moved out of bounds
    pub fn moveLeft(self: *Cursor, distance: usize) !void {
        if (self.col == 0) return;

        try self.stdout.writer().print("\x1b[{d}D", .{distance});
        try self.updatePosition();
    }

    pub fn moveDown(self: *Cursor, distance: usize) !void {
        if (self.row >= self.terminal.screen.size.row -| 1) return;

        try self.stdout.writer().print("\x1b[{d}B", .{distance});
        try self.updatePosition();
    }

    pub fn moveUp(self: *Cursor, distance: usize) !void {
        if (self.row == 0) return;

        try self.stdout.writer().print("\x1b[{d}A", .{distance});
        try self.updatePosition();
    }

    pub fn moveRight(self: *Cursor, distance: usize) !void {
        if (self.col >= self.terminal.screen.size.col -| 1) return;

        try self.stdout.writer().print("\x1b[{d}C", .{distance});
        try self.updatePosition();
    }

    pub fn moveToCoords(self: *Cursor, x: usize, y: usize) !void {
        if (x > self.terminal.screen.size.col or y > self.terminal.screen.size.row) return error.OutOfRange;

        try self.stdout.writer().print("\x1b[{d};{d}H", .{ x, y });
        try self.updatePosition();
    }

    pub fn updatePosition(self: *Cursor) !void {
        const stdout = self.stdout.writer();
        const stdin = self.terminal.stdin.reader();

        try stdout.writeAll("\x1b[6n");
        var buf: [32]u8 = undefined;
        const bytes_read = try stdin.read(&buf);

        const response = buf[0..bytes_read];

        if (response.len < 5) return error.InvalidResponse;

        if (response[0] != 0x1b or response[1] != '[' or response[bytes_read - 1] != 'R') {
            return error.InvalidResponse;
        }

        const data = response[2 .. bytes_read - 1];
        const semicolon = std.mem.indexOfScalar(u8, data, ';') orelse return error.InvalidResponse;

        const row_str = data[0..semicolon];
        const col_str = data[semicolon + 1 ..];

        const row = try std.fmt.parseInt(usize, row_str, 10);
        const col = try std.fmt.parseInt(usize, col_str, 10);

        self.row = row - 1;
        self.col = col - 1;
    }

    pub fn show(self: *const Cursor) !void {
        try self.stdout.writer().writeAll("\x1b[?25h");
    }

    pub fn hide(self: *const Cursor) !void {
        try self.stdout.writer().writeAll("\x1b[?25l");
    }
};
