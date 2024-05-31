const std = @import("std");
const rl = @import("raylib");

const Self = @This();

camera: rl.Camera3D,

pub fn update(self: *Self) void {
    rl.updateCamera(&self.camera, .camera_first_person);
}
