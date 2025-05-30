const std = @import("std");
pub const Color = @import("color.zig").Color;

pub const Modifier = enum(u16) {
    BOLD = 0b0000_0000_0001,
    DIM = 0b0000_0000_0010,
    ITALIC = 0b0000_0000_0100,
    UNDERLINED = 0b0000_0000_1000,
    SLOW_BLINK = 0b0000_0001_0000,
    RAPID_BLINK = 0b0000_0010_0000,
    REVERSED = 0b0000_0100_0000,
    HIDDEN = 0b0000_1000_0000,
    CROSSED_OUT = 0b0001_0000_0000,
    EMPTY = 0b0000_0000_0000,
    ALL = 0b0001_1111_1111,
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
            .add_modifier = .EMPTY,
            .sub_modifier = .ALL,
        };
    }

    pub fn reset() Style {
        return .{
            .foreground = .Reset,
            .background = .Reset,
            .underline_color = .Reset,
            .add_modifier = .EMPTY,
            .sub_modifier = .ALL,
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
};
