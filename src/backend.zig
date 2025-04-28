const std = @import("std");
const builtin = @import("builtin");

// Fields
//  - row: u16
//  - col: u16
//  - xpixel: u16,
//  - ypixel: u16,
const Linux = std.os.linux;
const Posix = std.posix;
const Winsize = Posix.winsize;
const Termios = Posix.termios;

pub const Backend = struct {
    stdin: std.fs.File,
    stdout: std.fs.File,

    pub fn init() Backend {
        return Backend{
            .stdin = std.io.getStdIn(),
            .stdout = std.io.getStdOut(),
        };
    }


    pub fn write(self: *const Backend, buf: []const u8) !void {
        try self.stdout.writer().print("{s}", .{ buf });
    }

    pub fn clear(self: *const Backend) !void {
        try self.stdout.writer().writeAll("\x1b[2J");
    }

//   pub fn flush() !void {
//   }
// 
    pub fn getSize(self: *const Backend, allocator: std.mem.Allocator) !*Winsize {
        if (builtin.target.os.tag == .linux) {
            const size = try allocator.create(Winsize);

            switch (Linux.ioctl(self.stdout.handle, Linux.T.IOCGWINSZ, @intFromPtr(size))) {
                0 => return size,
                else => return error.UnexpectedError,
            }
        } else {
            return error.NotOnLinux;
        }
    }
// 
//   pub fn showCursor() !void {
//   }
// 
//   pub fn hideCursor() !void {
//   }
};
