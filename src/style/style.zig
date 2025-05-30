const std = @import("std");
pub const Color = @import("color.zig").Color;

pub const Flags = struct {
    pub const BOLD: u16 = 0b0000_0000_0001;
    pub const DIM: u16 = 0b0000_0000_0010;
    pub const ITALIC: u16 = 0b0000_0000_0100;
    pub const UNDERLINED: u16 = 0b0000_0000_1000;
    pub const SLOW_BLINK: u16 = 0b0000_0001_0000;
    pub const RAPID_BLINK: u16 = 0b0000_0010_0000;
    pub const INVERT: u16 = 0b0000_0100_0000;
    pub const HIDDEN: u16 = 0b0000_1000_0000;
    pub const CROSSED_OUT: u16 = 0b0001_0000_0000;
    pub const EMPTY: u16 = 0b0000_0000_0000;
    pub const ALL: u16 = 0b0001_1111_1111;
};

pub const Modifier = packed struct {
    bits: u16,

    pub fn init(bits: u16) Modifier {
        return .{ .bits = bits };
    }

    fn has(self: Modifier, flag: u16) bool {
        return (self.bits & flag) != 0;
    }

    pub fn apply(self: Modifier) !void {
        const writer = std.io.getStdOut().writer();

        if (self.bits == 0) return;

        if (self.has(Flags.BOLD)) try writer.print("\x1b[{d}m", .{ 1 });
        if (self.has(Flags.DIM)) try writer.print("\x1b[{d}m", .{ 2 });
        if (self.has(Flags.ITALIC)) try writer.print("\x1b[{d}m", .{ 3 });
        if (self.has(Flags.UNDERLINED)) try writer.print("\x1b[{d}m", .{ 4 });
        if (self.has(Flags.SLOW_BLINK)) try writer.print("\x1b[{d}m", .{ 5 });
        if (self.has(Flags.RAPID_BLINK)) try writer.print("\x1b[{d}m", .{ 6 });
        if (self.has(Flags.INVERT)) try writer.print("\x1b[{d}m", .{ 7 });
        if (self.has(Flags.HIDDEN)) try writer.print("\x1b[{d}m", .{ 8 });
        if (self.has(Flags.CROSSED_OUT)) try writer.print("\x1b[{d}m", .{ 9 });
    }

    pub fn exempt(self: Modifier) !void {
        const writer = std.io.getStdOut().writer();

        if (self.bits == 0) try writer.print("\x1b[{d}m", .{ 0 });

        if (self.has(Flags.BOLD)) try writer.print("\x1b[{d}m", .{ 22 });
        if (self.has(Flags.DIM)) try writer.print("\x1b[{d}m", .{ 22 });
        if (self.has(Flags.ITALIC)) try writer.print("\x1b[{d}m", .{ 23 });
        if (self.has(Flags.UNDERLINED)) try writer.print("\x1b[{d}m", .{ 24 });
        if (self.has(Flags.SLOW_BLINK)) try writer.print("\x1b[{d}m", .{ 25 });
        if (self.has(Flags.RAPID_BLINK)) try writer.print("\x1b[{d}m", .{ 25 });
        if (self.has(Flags.INVERT)) try writer.print("\x1b[{d}m", .{ 27 });
        if (self.has(Flags.HIDDEN)) try writer.print("\x1b[{d}m", .{ 28 });
        if (self.has(Flags.CROSSED_OUT)) try writer.print("\x1b[{d}m", .{ 29 });
    }
};

pub const Style = struct {
    foreground: ?Color,
    background: ?Color,
    underline_color: ?Color,
    add_modifier: Modifier,
    sub_modifier: Modifier,

    pub fn init() Style {
        return .{
            .foreground = null,
            .background = null,
            .underline_color = null,
            .add_modifier = Modifier.init(Flags.EMPTY),
            .sub_modifier = Modifier.init(Flags.ALL),
        };
    }

    pub fn reset() Style {
        return .{
            .foreground = .Reset,
            .background = .Reset,
            .underline_color = .Reset,
            .add_modifier = Modifier.init(Flags.EMPTY),
            .sub_modifier = Modifier.init(Flags.ALL),
        };
    }

    pub fn fg(self: *Style, color: Color) void {
        self.foreground = color;
    }

    pub fn bg(self: *Style, color: Color) void {
        self.background = color;
    }

    pub fn underlineColor(self: *Style, color: Color) void {
        self.underline_color = color;
    }

    pub fn addModifier(self: *Style, flags: u16) void {
        self.add_modifier.bits |= flags;
        self.sub_modifier.bits &= ~flags;
    }

    pub fn removeModifier(self: *Style, flags: u16) void {
        self.add_modifier.flags &= ~flags;
        self.sub_modifier.flags |= flags;
    }
};
