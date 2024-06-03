const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const Stat = @import("../gameplay/stat.zig").Stat;
const TargetHandler = @import("TargetHandler.zig");

const Self = @This();

const game = &@import("../Game.zig").game;

const AVOID_DISTANCE = 500.0;

const HareGenotype = struct {
    hunger_growth_factor: f32,
    thirst_growth_factor: f32,
    social_decay_factor: f32,

    hunger_max: f32,
    thirst_max: f32,

    social_min: f32,
    social_max: f32,

    pub fn random() HareGenotype {
        return .{
            .hunger_growth_factor = 1.0 + game.rnd.float() * 0.1,
            .thirst_growth_factor = 1.0 + game.rnd.float() * 0.1,
            .social_decay_factor = 1.0 + game.rnd.float() * 0.1,

            .hunger_max = 0.6 + game.rnd.float() * 0.2, // 0.6..0.8
            .thirst_max = 0.7 + game.rnd.float() * 0.1, // 0.7..0.8

            .social_min = 0.0 + game.rnd.float() * 0.5, // 0.0..0.5
            .social_max = 0.5 + game.rnd.float() * 0.5, // 0.5..1.0
        };
    }
};

position: rl.Vector3,
target_handler: TargetHandler,
speed: f32 = 0.4,

genotype: HareGenotype,

thirst: Stat(f32, .{}) = .{ .value = 0.25, .delta = 0.001 },
//mating: Stat(f32, .{}) = .{ .value = 0.25, .delta = -0.0004 },

state: enum {
    idleWandering,
    escapingPredator,
    lookingForWater,
} = .idleWandering,

pub fn init(opts: struct {
    position: rl.Vector3 = rl.Vector3.init(10, 0, 10),
}) Self {
    var self = Self{
        .position = opts.position,
        .target_handler = TargetHandler{ .position = opts.position },
        .genotype = HareGenotype.random(),
    };
    self.thirst.delta *= self.genotype.thirst_growth_factor;
    return self;
}

pub fn update(self: *Self) !void {
    self.thirst.update();

    if (self.thirst.value > self.genotype.thirst_max) {
        if (self.state != .lookingForWater) self.target_handler.target = null;
        self.state = .lookingForWater;
    } else {
        if (self.state != .idleWandering) self.target_handler.target = null;
        self.state = .idleWandering;
    }

    const closestFox = self.getClosestFox();
    if (closestFox) |_| {
        self.state = .escapingPredator;
    }

    switch (self.state) {
        .idleWandering => {
            if (self.target_handler.isIdle() and game.rnd.float() < 0.3) {
                self.target_handler.autoSetTargetRandom(self.position);
            }
            self.speed = 0.2;
        },
        .escapingPredator => {
            self.target_handler.setAvoidTarget(closestFox.?, AVOID_DISTANCE);
            self.speed = 0.6;
        },
        .lookingForWater => {
            if (self.target_handler.isIdle()) {
                self.target_handler.autoSetTargetRandom(self.position);
            }
            self.speed = 0.6;
        },
    }

    if (self.target_handler.getDirection()) |dir| {
        self.position = rlm.vector3Add(self.position, rlm.vector3Scale(dir, self.speed));
        self.position.y = game.modules.world.getY(self.position.x, self.position.z);
        self.target_handler.updatePosition(self.position);
    }
}

fn getClosestFox(self: *Self) ?rl.Vector3 {
    var closestFox: ?rl.Vector3 = null;
    var closestDistance: f32 = 100000.0;
    for (game.modules.foxes.array.items) |fox| {
        const distance = rlm.vector3DistanceSqr(fox.position, self.position);
        if (distance < closestDistance) {
            closestDistance = distance;
            closestFox = fox.position;
        }
    }
    if (closestDistance > AVOID_DISTANCE) return null;
    return closestFox;
}

pub fn draw(self: *const Self) void {
    var modelPosition = self.position;
    modelPosition.y += 1.0;
    rl.drawCube(self.position, 2.0, 2.0, 2.0, rl.Color.dark_brown);

    self.target_handler.draw();
}
