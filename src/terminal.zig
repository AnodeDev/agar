// Holds all the terminal-related code

const std = @import("std");
const builtin = @import("builtin");
const screen_mod = @import("screen.zig");
const cursor_mod = @import("cursor.zig");
const widgets_mod = @import("widgets.zig");

const Stdout = std.io.stdout;
const posix = std.posix;
const linux = std.os.linux;
const Screen = screen_mod.Screen;
const Cursor = cursor_mod.Cursor;
const Widget = widgets_mod.Widget;

// Main struct that holds information about the TTY and its state
pub const Terminal = struct {
    allocator: std.mem.Allocator,
    default_state: posix.termios, // Original TTY state
    stdin: std.fs.File, // Holds the TTY handle, which is required by Termios
    cursor: Cursor,
    screen: Screen,
    widgets: std.ArrayList(Widget),

    pub fn init(allocator: std.mem.Allocator) !*Terminal {
        const stdin = std.io.getStdIn();

        // Checks if the current handle is a TTY, otherwise it throws an error
        if (posix.isatty(stdin.handle)) {
            const default_state = try posix.tcgetattr(stdin.handle); // Gets the current state of the TTY
            var terminal = try allocator.create(Terminal);
            const widgets = std.ArrayList(Widget).init(allocator);

            terminal.* = Terminal{
                .allocator = allocator,
                .default_state = default_state,
                .stdin = stdin,
                .cursor = undefined,
                .screen = undefined,
                .widgets = widgets,
            };

            terminal.screen = try Screen.init(terminal);
            terminal.cursor = Cursor.init(terminal);

            return terminal;
        } else {
            return error.NotATerminal; // If the stdin handle isn't a TTY
        }
    }

    pub fn deinit(self: *const Terminal) void {
        self.exitRawMode() catch return;
        for (self.widgets.items) |widget| {
            widget.deinit();
        }
        self.widgets.deinit();
        self.allocator.destroy(self);
    }

    // Enters Raw mode by disabling ICanon and Echo
    pub fn enterRawMode(self: *const Terminal) !void {
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

    pub fn exitRawMode(self: *const Terminal) !void {
        posix.tcsetattr(self.stdin.handle, .NOW, self.default_state) catch return; // Applies the original state to the TTY
    }

    pub fn addWidget(self: *Terminal, widget: Widget) !void {
        try self.widgets.append(widget);
    }
};
