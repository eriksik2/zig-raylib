const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const Pathfinder = @import("Pathfinder.zig");

const Self = @This();

const game = &@import("Game.zig").game;

position: rl.Vector3,
pathfinder: Pathfinder,
speed: f32 = 0.4,

pub fn init(opts: struct {
    position: rl.Vector3 = rl.Vector3.init(10, 0, 10),
    speed: f32 = 0.4,
}) Self {
    return Self{
        .position = opts.position,
        .speed = opts.speed,
        .pathfinder = Pathfinder.init(opts.position),
    };
}

pub fn update(self: *Self) !void {
    self.position.y = game.modules.world.getY(self.position.x, self.position.z);

    var playerPos = game.modules.player.camera.position;
    playerPos.y = game.modules.world.getY(playerPos.x, playerPos.z);
    self.pathfinder.updateTarget(playerPos);

    if (try self.pathfinder.getNextPathPoint()) |point| {
        const dir = rlm.vector3Normalize(rlm.vector3Subtract(point, self.position));
        self.position = rlm.vector3Add(self.position, rlm.vector3Scale(dir, self.speed));
    }

    self.pathfinder.updateOrigin(self.position);
}

pub fn draw(self: *const Self) void {
    rl.drawCube(self.position, 2.0, 2.0, 2.0, rl.Color.red);

    self.pathfinder.draw();
}
