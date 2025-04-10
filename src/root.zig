const std = @import("std");

const posix = std.posix;
const linux = std.os.linux;

const Term = struct {
    default_state: posix.termios,
    stdin: std.fs.File,
    stdout: std.fs.File,

    fn init() !Term {
        const stdin = std.io.getStdIn();

        if (posix.isatty(stdin.handle)) {
            const stdout = std.io.getStdOut();
            const default_state = try posix.tcgetattr(stdin.handle);
            var new_state = default_state;

            new_state.lflag = linux.tc_lflag_t{
                .ICANON = true,
                .ECHO = true,
            };

            try posix.tcsetattr(stdin.handle, .FLUSH, new_state);

            return Term{
                .default_state = default_state,
                .stdin = stdin,
                .stdout = stdout,
            };
        } else {
            return error.NotATerminal;
        }
    }

    fn deinit(self: *const Term) void {
        posix.tcsetattr(self.stdin.handle, .FLUSH, self.default_state) catch {};
    }

    fn clear(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[2J\x1b[H");
    }

    fn clearAll(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[3J\x1b[H");
    }
};

pub fn main() !void {
    const term = try Term.init();
    defer term.deinit();

    try term.clear();
    try term.stdout.writer().writeAll("Hello TUI!\n");
}
