const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const Self = @This();

const game = &@import("Game.zig").game;

const min_distance = 0.1;

origin: rl.Vector3,
target: ?rl.Vector3,
path: ?[]rl.Vector3,
path_progress: u32,

pub fn updateOrigin(self: *Self, newOrigin: rl.Vector3) !void {
    if (self.target == null) {
        self.origin = newOrigin;
        return;
    }
    if (self.getNextPathPoint()) |npp| {
        const oldDistance = rlm.vector3DistanceSqr(self.origin, npp);
        const newDistance = rlm.vector3DistanceSqr(newOrigin, npp);
        if (newDistance > oldDistance) {
            try self.calculatePath();
        }
    } else {
        try self.calculatePath();
    }
    self.origin = newOrigin;
}

pub fn getNextPathPoint(self: *Self) ?rl.Vector3 {
    if (self.path == null) {
        return null;
    }
    return self.path[self.path_progress];
}

fn calculatePath(self: *Self) !void {
    if (self.target == null) unreachable;
    if (self.path != null) {
        game.allocator.free(self.path);
    }

    // temporary pathfinding
    self.path = game.allocator.alloc(u32, 1);
    self.path[0] = self.target;

    self.path_progress = 0;
}
