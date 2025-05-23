const std = @import("std");
const terminal_mod = @import("terminal.zig");
const widget_mod = @import("widget.zig");

const Terminal = terminal_mod.Terminal;
const Widget = widget_mod.Widget;
const Constraint = widget_mod.Constraint;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Data Leaked");
    }
    var tty = try Terminal.init(allocator);
    defer tty.deinit(allocator);

    try tty.enterRawMode();
    try tty.enableAlternativeBuffer();
    try tty.backend.hideCursor();

    const frame = tty.getFrame();
    const paragraph = Widget.paragraph(allocator, "Hello everybody!");
    defer allocator.destroy(paragraph);
    const area = frame.area();
    const constraints = [_]Constraint{
        Constraint{ .Length = 10 },
        Constraint{ .Length = 10 },
        Constraint{ .Length = 10 },
    };

    const smol_widgets = try widget_mod.vertical(allocator, constraints[0..], area);
    defer allocator.free(smol_widgets);

    try frame.renderWidget(allocator, paragraph, smol_widgets[0]);
    try frame.renderWidget(allocator, paragraph, smol_widgets[1]);
    try frame.renderWidget(allocator, paragraph, smol_widgets[2]);

    std.Thread.sleep(10000000000);
    try tty.backend.showCursor();
}
