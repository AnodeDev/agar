const std = @import("std");
const agar = @import("agar");

const Terminal = agar.terminal.Terminal;
const Constraint = agar.widget.Constraint;
const Widget = agar.widget.Widget;
const Block = agar.widget.Block;

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
    const block = Block.bordered(allocator, .All).assignTitle("Good morning!");
    defer block.deinit(allocator);
    const area = frame.area();

    try frame.renderWidget(allocator, block.widget(), area);

    std.Thread.sleep(5000000000);
    try tty.backend.showCursor();
}
