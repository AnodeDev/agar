const std = @import("std");
const widget_mod = @import("widget.zig");

const Widget = widget_mod.Widget;
const Rect = widget_mod.Rect;

const Frame = struct {
    pub fn render_widget(widget: Widget, area: Rect) void {
    }
};
