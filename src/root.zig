const std = @import("std");
const builtin = @import("builtin");

const posix = std.posix;
const linux = std.os.linux;

const Term = struct {
    default_state: posix.termios,
    stdin: std.fs.File,
    stdout: std.fs.File,
    size: posix.winsize,

    fn init() !Term {
        const stdin = std.io.getStdIn();

        if (posix.isatty(stdin.handle)) {
            const stdout = std.io.getStdOut();
            const winsize = posix.winsize{
                .row = 0,
                .col = 0,
                .xpixel = 0,
                .ypixel = 0,
            };
            const default_state = try posix.tcgetattr(stdin.handle);
            var new_state = default_state;

            new_state.lflag = linux.tc_lflag_t{
                .ICANON = true,
                .ECHO = true,
            };

            try posix.tcsetattr(stdin.handle, .FLUSH, new_state);
            
            var term = Term{
                .default_state = default_state,
                .stdin = stdin,
                .stdout = stdout,
                .size = winsize,
            };

            try term.assignSize();

            return term;
        } else {
            return error.NotATerminal;
        }
    }

    fn deinit(self: *const Term) void {
        posix.tcsetattr(self.stdin.handle, .NOW, self.default_state) catch {};
    }

    fn clear(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[2J");
    }

    fn assignSize(self: *Term) !void {
        if (builtin.target.os.tag == .linux) {
            switch (linux.ioctl(self.stdin.handle, linux.T.IOCGWINSZ, @intFromPtr(&self.size))) {
                0 => return,
                else => return error.UnexpectedError,
            }
        }

        return error.NotOnLinux;
    }

    fn resetCursor(self: *Term) !void {
        try self.stdout.writer().writeAll("\x1b[H");
    }

    fn moveCursorLeft(self: *Term, distance: usize) !void {
        try self.stdout.writer().print("\x1b[{d}D", .{ distance });
    }

    fn moveCursorDown(self: *Term, distance: usize) !void {
        try self.stdout.writer().print("\x1b[{d}B", .{ distance });
    }

    fn moveCursorUp(self: *Term, distance: usize) !void {
        try self.stdout.writer().print("\x1b[{d}A", .{ distance });
    }

    fn moveCursorRight(self: *Term, distance: usize) !void {
        try self.stdout.writer().print("\x1b[{d}C", .{ distance });
    }

    fn moveCursorToCoords(self: *Term, x: usize, y: usize) !void {
        if (x > self.size.col or y > self.size.row) return error.OutOfRange;

        try self.stdout.writer().print("\x1b[{d};{d}H", .{ x, y });
    }
};
