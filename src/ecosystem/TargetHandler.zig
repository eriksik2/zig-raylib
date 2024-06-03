const rl = @import("raylib");
const rlm = @import("raylib-math");

const Self = @This();

const game = &@import("../Game.zig").game;

target: ?rl.Vector3 = null,
avoid: bool = false,
position: rl.Vector3,
distance: f32 = 0.0,
max_distance: f32 = 10.0,

pub fn updatePosition(self: *Self, position: rl.Vector3) void {
    self.position = position;
    if (self.target) |target| {
        self.distance = rlm.vector3DistanceSqr(target, self.position);
    }
}

fn _setTarget(self: *Self, target: rl.Vector3, max_distance: f32) void {
    const distance = rlm.vector3DistanceSqr(target, self.position);
    if (self.distanceSatisfied(distance, max_distance)) {
        return;
    }
    self.target = target;
    self.distance = distance;
    self.max_distance = max_distance;
}

pub fn setTarget(self: *Self, target: rl.Vector3, max_distance: f32) void {
    self.avoid = false;
    self._setTarget(target, max_distance);
}

pub fn setAvoidTarget(self: *Self, target: rl.Vector3, max_distance: f32) void {
    self.avoid = true;
    self._setTarget(target, max_distance);
}

pub fn stop(self: *Self) void {
    self.target = null;
}

pub fn isIdle(self: *Self) bool {
    if (self.target == null) {
        return true;
    }
    if (self.distanceSatisfied(self.distance, self.max_distance)) {
        self.target = null;
        return true;
    }
    return false;
}

fn distanceSatisfied(self: *Self, distance: f32, max: f32) bool {
    if (self.avoid) return distance >= max;
    return distance < max;
}

pub fn getDirection(self: *Self) ?rl.Vector3 {
    if (self.target == null) {
        return null;
    }

    const target = self.target.?;
    const dir = rlm.vector3Subtract(target, self.position);
    const distance = dir.x * dir.x + dir.y * dir.y + dir.z * dir.z;
    if (self.distanceSatisfied(distance, self.max_distance)) {
        self.target = null;
        return null;
    }

    const dirNorm = rlm.vector3Normalize(dir);
    if (self.avoid) return rlm.vector3Scale(dirNorm, -1.0);
    return dirNorm;
}

pub fn autoSetTargetRandom(self: *Self, position: rl.Vector3) void {
    const worldPos = game.modules.world.position;
    const worldSize = rl.Vector3{
        .x = @as(f32, @floatFromInt(game.modules.world.size.x)),
        .y = 0,
        .z = @as(f32, @floatFromInt(game.modules.world.size.z)),
    };
    const worldEndPos = rlm.vector3Add(game.modules.world.position, rlm.vector3Scale(worldSize, 2.0));

    const RANGE = 20.0;

    var pos = position;

    if (pos.x - RANGE < worldPos.x) {
        pos.x = worldPos.x + RANGE;
    }
    if (pos.x + RANGE > worldEndPos.x) {
        pos.x = worldEndPos.x - RANGE;
    }
    if (pos.z - RANGE < worldPos.z) {
        pos.z = worldPos.z + RANGE;
    }
    if (pos.z + RANGE > worldEndPos.z) {
        pos.z = worldEndPos.z - RANGE;
    }

    const x = RANGE * (game.rnd.float() * 2 - 1) + pos.x;
    const z = RANGE * (game.rnd.float() * 2 - 1) + pos.z;

    const rndPos = rl.Vector3{
        .x = x,
        .y = game.modules.world.getY(x, z),
        .z = z,
    };
    self.setTarget(rndPos, 1.0);
}

pub fn draw(self: *const Self) void {
    if (self.target) |target| {
        _ = target; // autofix
        const color = if (self.avoid) rl.Color.red else rl.Color.green;
        _ = color; // autofix
        //rl.drawLine3D(self.position, target, color);
    }
}
