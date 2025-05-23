// Holds all the terminal-related code

const std = @import("std");
const builtin = @import("builtin");
const backend_mod = @import("backend.zig");
const frame_mod = @import("frame.zig");

const posix = std.posix;
const linux = std.os.linux;
const Termios = posix.termios;
const Backend = backend_mod.Backend;
const Frame = frame_mod.Frame;

// Main struct that holds information about the TTY and its state
pub const Terminal = struct {
    backend: Backend,
    default_state: Termios,

    pub fn init(allocator: std.mem.Allocator) !*Terminal {
        const stdin = std.io.getStdIn();
        // Checks if the current handle is a TTY, otherwise it throws an error
        if (posix.isatty(stdin.handle)) {
            const terminal = try allocator.create(Terminal);
            const default_state = try posix.tcgetattr(stdin.handle);

            terminal.* = .{
                .backend = try Backend.init(allocator),
                .default_state = default_state,
            };

            return terminal;
        } else {
            return error.NotATerminal;
        }
    }

    pub fn deinit(self: *const Terminal, allocator: std.mem.Allocator) void {
        // Resets terminal state
        self.disableAlternativeBuffer() catch return;
        self.exitRawMode() catch return;

        // Frees memory
        self.backend.deinit(allocator);
        allocator.destroy(self);
    }

    // Enters Raw mode by disabling ICanon and Echo
    pub fn enterRawMode(self: *const Terminal) !void {
        // Linux is currently the only supported OS
        if (builtin.target.os.tag == .linux) {
            var new_state = self.default_state;

            new_state.lflag = linux.tc_lflag_t{
                .ICANON = false,
                .ECHO = false,
            };

            try posix.tcsetattr(self.backend.stdin.handle, .FLUSH, new_state);

            return;
        } else {
            return error.NotOnLinux;
        }
    }

    pub fn exitRawMode(self: *const Terminal) !void {
        posix.tcsetattr(self.backend.stdin.handle, .NOW, self.default_state) catch return; // Applies the original state to the TTY
    }

    pub fn enableAlternativeBuffer(self: *const Terminal) !void {
        try self.backend.write("\x1b[?1049h");
    }

    pub fn disableAlternativeBuffer(self: *const Terminal) !void {
        try self.backend.write("\x1b[?1049l");
    }

    pub fn getFrame(self: *Terminal) Frame {
        return Frame{ .ptr = self };
    }
};
