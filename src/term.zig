// Holds all the terminal-related code
// It handles:
//  - Raw mode
//  - Cursor manipulation

const std = @import("std");
const builtin = @import("builtin");

const posix = std.posix;
const linux = std.os.linux;

const Cursor = struct {
    row: usize,
    col: usize,

    fn init() Cursor {
        return Cursor{
            .row = 0,
            .col = 0,
        };
    }
};

// Main struct that holds information about the TTY and its state
pub const Term = struct {
    default_state: posix.termios, // Original TTY state
    stdin: std.fs.File, // Holds the TTY handle, which is required by Termios
    stdout: std.fs.File,
    size: posix.winsize, // The size of the TTY
    cursor: Cursor,
    raw_mode: bool,

    pub fn init() !Term {
        const stdin = std.io.getStdIn();

        // Checks if the current handle is a TTY, otherwise it throws an error
        if (posix.isatty(stdin.handle)) {
            const stdout = std.io.getStdOut();
            const cursor = Cursor.init();
            const winsize = posix.winsize{ // Creates an empty winsize to be filled later
                .row = 0,
                .col = 0,
                .xpixel = 0,
                .ypixel = 0,
            };
            // Gets the current state of the TTY
            const default_state = try posix.tcgetattr(stdin.handle);

            var term = Term{
                .default_state = default_state,
                .stdin = stdin,
                .stdout = stdout,
                .size = winsize,
                .cursor = cursor,
                .raw_mode = false,
            };

            try term.assignSize(); // Fills the winsize field

            return term;
        } else {
            return error.NotATerminal; // If the stdin handle isn't a TTY
        }
    }

    pub fn deinit(self: *const Term) void {
        posix.tcsetattr(self.stdin.handle, .NOW, self.default_state) catch {}; // Applies the original state to the TTY
    }

    // Enters Raw mode by disabling ICanon and Echo
    pub fn enterRawMode(self: *const Term) !void {
        if (builtin.target.os.tag == .linux) {
            var new_state = self.default_state;

            new_state.lflag = linux.tc_lflag_t{
                .ICANON = false,
                .ECHO = false,
            };

            try posix.tcsetattr(self.stdin.handle, .FLUSH, new_state);

            return;
        }

        return error.NotOnLinux;
    }

    // Clears the entire screen
    pub fn clear(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[2J");
    }

    // Assigns the TTY size to the struct field 'size'
    pub fn assignSize(self: *Term) !void {
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
    pub fn resetCursor(self: *Term) !void {
        try self.stdout.writer().writeAll("\x1b[H");
        try self.updateCursorPosition();
    }

    // TODO: Add boundary checks to make sure the cursor isn't moved out of bounds
    pub fn moveCursorLeft(self: *Term, distance: usize) !void {
        if (self.cursor.col <= 0) return;

        try self.stdout.writer().print("\x1b[{d}D", .{ distance });
        try self.updateCursorPosition();
    }

    pub fn moveCursorDown(self: *Term, distance: usize) !void {
        if (self.cursor.row >= self.size.row - 1) return;

        try self.stdout.writer().print("\x1b[{d}B", .{ distance });
        try self.updateCursorPosition();
    }

    pub fn moveCursorUp(self: *Term, distance: usize) !void {
        if (self.cursor.row <= 0) return;

        try self.stdout.writer().print("\x1b[{d}A", .{ distance });
        try self.updateCursorPosition();
    }

    pub fn moveCursorRight(self: *Term, distance: usize) !void {
        if (self.cursor.col >= self.size.col - 1) return;

        try self.stdout.writer().print("\x1b[{d}C", .{ distance });
        try self.updateCursorPosition();
    }

    pub fn moveCursorToCoords(self: *Term, x: usize, y: usize) !void {
        if (x > self.size.col or y > self.size.row) return error.OutOfRange;

        try self.stdout.writer().print("\x1b[{d};{d}H", .{ x, y });
        try self.updateCursorPosition();
    }

    pub fn updateCursorPosition(self: *Term) !void {
        const stdout = self.stdout.writer();
        const stdin = self.stdin.reader();

        try stdout.writeAll("\x1b[6n");
        var buf: [32]u8 = undefined;
        const bytes_read = try stdin.read(&buf);

        const response = buf[0..bytes_read];

        if (response.len < 5) return error.InvalidResponse;

        if (response[0] != 0x1b or response[1] != '[' or response[bytes_read-1] != 'R') {
            return error.InvalidResponse;
        }

        const data = response[2..bytes_read-1];
        const semicolon = std.mem.indexOfScalar(u8, data, ';') orelse return error.InvalidResponse;

        const row_str = data[0..semicolon];
        const col_str = data[semicolon+1..];

        const row = try std.fmt.parseInt(usize, row_str, 10);
        const col = try std.fmt.parseInt(usize, col_str, 10);

        self.cursor.row = row;
        self.cursor.col = col;
    }

    pub fn showCursor(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[?25h");
    }

    pub fn hideCursor(self: *const Term) !void {
        try self.stdout.writer().writeAll("\x1b[?25l");
    }
};
