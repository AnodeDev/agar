const std = @import("std");
const builtin = @import("builtin");
const terminal_mod = @import("terminal.zig");

const posix = std.posix;
const linux = std.os.linux;
const Terminal = terminal_mod.Terminal;

// Fields
//  - row: u16
//  - col: u16
//  - xpixel: u16,
//  - ypixel: u16,
const winsize = std.posix.winsize;

pub const Screen = struct {
    terminal: *Terminal,
    size: winsize,
    stdout: std.fs.File,

    pub fn init(terminal: *Terminal) !Screen {
        const stdout = std.io.getStdOut();
        var screen = Screen{
            .terminal = terminal,
            .size = undefined,
            .stdout = stdout,
        };

        try screen.assignSize();

        return screen;
    }

    // Clears the entire screen
    pub fn clear(self: *const Screen) !void {
        _ = try self.stdout.writer().write("\x1b[2J");
    }

    // Assigns the TTY size to the struct field 'size'
    pub fn assignSize(self: *Screen) !void {
        if (builtin.target.os.tag == .linux) {
            // Checks the result of 'ioctl' and returns the appropriate value
            // TODO: Add a proper unexpected return to include the error code
            switch (linux.ioctl(self.terminal.stdin.handle, linux.T.IOCGWINSZ, @intFromPtr(&self.size))) {
                0 => return,
                else => return error.UnexpectedError,
            }
        }

        return error.NotOnLinux;
    }
};
