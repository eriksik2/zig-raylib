const std = @import("std");
const rl = @import("raylib");

const Self = @This();

position: rl.Vector3 = .{ .x = 0, .y = 0, .z = 0 },

pub fn draw(self: *const Self) void {
    rl.drawCube(self.position, 2.0, 2.0, 2.0, rl.Color.red);
}
