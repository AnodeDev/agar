const std = @import("std");
const builtin = @import("builtin");

const posix = std.posix;
const linux = std.os.linux;

// Main struct that holds information about the TTY and its state
const Term = struct {
    default_state: posix.termios, // Original TTY state
    stdin: std.fs.File, // Holds the TTY handle, which is required by Termios
    stdout: std.fs.File,
    size: posix.winsize, // The size of the TTY

    fn init() !Term {
        const stdin = std.io.getStdIn();

        // Checks if the current handle is a TTY, otherwise it throws an error
        if (posix.isatty(stdin.handle)) {
            const stdout = std.io.getStdOut();
            const winsize = posix.winsize{ // Creates an empty winsize to be filled later
                .row = 0,
                .col = 0,
                .xpixel = 0,
                .ypixel = 0,
            };
            // Gets the current state of the TTY and copies it into a new variable
            const default_state = try posix.tcgetattr(stdin.handle);
            var new_state = default_state;

            // Disables ICanon and Echo
            new_state.lflag = linux.tc_lflag_t{
                .ICANON = false,
                .ECHO = false,
            };

            // Applies the new state to the TTY
            try posix.tcsetattr(stdin.handle, .FLUSH, new_state);
            
            var term = Term{
                .default_state = default_state,
                .stdin = stdin,
                .stdout = stdout,
                .size = winsize,
            };

            try term.assignSize(); // Fills the winsize

            return term;
        } else {
            return error.NotATerminal; // If the stdin handle isn't a TTY
        }
    }

    fn deinit(self: *const Term) void {
        posix.tcsetattr(self.stdin.handle, .NOW, self.default_state) catch {}; // Applies the original state to the TTY
    }

    // Clears the entire screen
    fn clear(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[2J");
    }

    // Assigns the TTY size to the struct field 'size'
    fn assignSize(self: *Term) !void {
        if (builtin.target.os.tag == .linux) {
            // Checks the result of 'ioctl' and returns the appropriate value
            // TODO: Add a proper unexpected return to include the error code
            switch (linux.ioctl(self.stdin.handle, linux.T.IOCGWINSZ, @intFromPtr(&self.size))) {
                0 => return,
                else => return error.UnexpectedError,
            }
        }

        return error.NotOnLinux;
    }

    // Brings the cursor back to (0, 0)
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
