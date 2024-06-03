const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const Stat = @import("../gameplay/stat.zig").Stat;
const TargetHandler = @import("TargetHandler.zig");

const Self = @This();

const game = &@import("../Game.zig").game;

const SOCIAL_DISTANCE = 100.0;
const AVOID_DISTANCE = 500.0;
const CHASE_DISTANCE = 400.0;

const FoxGenotype = struct {
    hunger_growth_factor: f32,
    thirst_growth_factor: f32,
    social_decay_factor: f32,

    hunger_max: f32,
    thirst_max: f32,

    social_min: f32,
    social_max: f32,

    pub fn random() FoxGenotype {
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

genotype: FoxGenotype,

hunger: Stat(f32, .{}) = .{ .value = 0.25, .delta = 0.0006 },
thirst: Stat(f32, .{}) = .{ .value = 0.25, .delta = 0.00015 },
social: Stat(f32, .{}) = .{ .value = 0.25 },
//mating: Stat(f32, .{}) = .{ .value = 0.25, .delta = -0.0004 },

mood: Stat(f32, .{}) = .{ .value = 0.5 },

state: enum {
    idleWandering,
    lookingForFood,
    lookingForWater,
    lookingForSocial,
    avoidingSocial,
} = .idleWandering,

pub fn init(opts: struct {
    position: rl.Vector3 = rl.Vector3.init(10, 0, 10),
}) Self {
    var self = Self{
        .position = opts.position,
        .target_handler = TargetHandler{ .position = opts.position },
        .genotype = FoxGenotype.random(),
    };
    self.hunger.delta *= self.genotype.hunger_growth_factor;
    self.thirst.delta *= self.genotype.thirst_growth_factor;
    return self;
}

pub fn update(self: *Self) !void {
    self.hunger.update();
    self.thirst.update();

    var socialDelta: f32 = 0;
    if (self.getClosestFox(SOCIAL_DISTANCE)) |_| {
        socialDelta = 0.0006;
    } else {
        socialDelta = -0.0004;
    }
    self.social.delta = socialDelta;
    self.social.delta *= self.genotype.social_decay_factor;
    self.social.update();

    var moodDelta: f32 = 0.0;
    if (self.hunger.value > self.genotype.hunger_max) {
        if (self.state != .lookingForFood) self.target_handler.target = null;
        self.state = .lookingForFood;
        moodDelta -= 0.0001;
    } else if (self.thirst.value > self.genotype.thirst_max) {
        if (self.state != .lookingForWater) self.target_handler.target = null;
        self.state = .lookingForWater;
        moodDelta -= 0.0001;
    } else if (self.social.value < self.genotype.social_min) {
        if (self.state != .lookingForSocial) self.target_handler.target = null;
        self.state = .lookingForSocial;
        moodDelta -= 0.000025;
    } else if (self.social.value > self.genotype.social_max) {
        if (self.state != .avoidingSocial) self.target_handler.target = null;
        self.state = .avoidingSocial;
        moodDelta -= 0.0003;
    } else {
        if (self.state != .idleWandering) self.target_handler.target = null;
        self.state = .idleWandering;
    }

    self.mood.delta = moodDelta;
    self.mood.update();

    switch (self.state) {
        .idleWandering => {
            if (self.target_handler.isIdle() and game.rnd.float() < 0.3) {
                self.target_handler.autoSetTargetRandom(self.position);
            }
            self.speed = 0.2;
        },
        .lookingForFood => {
            if (self.target_handler.isIdle()) {
                if (self.getClosestHare()) |harePos| {
                    if (rlm.vector3DistanceSqr(harePos, self.position) < 5.0) {
                        self.hunger.value = 0.0;
                        self.target_handler.target = null;
                        self.state = .idleWandering;
                    } else {
                        self.target_handler.setTarget(harePos, 5.0);
                    }
                } else {
                    self.target_handler.autoSetTargetRandom(self.position);
                }
            }
            self.speed = 0.6;
        },
        .lookingForWater => {
            if (self.target_handler.isIdle()) {
                self.target_handler.autoSetTargetRandom(self.position);
            }
            self.speed = 0.6;
        },
        .lookingForSocial => {
            if (self.target_handler.isIdle()) {
                if (self.getClosestFox(SOCIAL_DISTANCE)) |foxPos| {
                    self.target_handler.setTarget(foxPos, SOCIAL_DISTANCE);
                } else {
                    self.target_handler.autoSetTargetRandom(self.position);
                }
            }
            self.speed = 0.4;
        },
        .avoidingSocial => {
            if (self.target_handler.isIdle()) {
                if (self.getClosestFox(AVOID_DISTANCE)) |foxPos| {
                    self.target_handler.setAvoidTarget(foxPos, AVOID_DISTANCE);
                } else {
                    self.target_handler.autoSetTargetRandom(self.position);
                }
            }
            self.speed = 0.4;
        },
    }

    if (self.target_handler.getDirection()) |dir| {
        self.position = rlm.vector3Add(self.position, rlm.vector3Scale(dir, self.speed));
        self.position.y = game.modules.world.getY(self.position.x, self.position.z);
        self.target_handler.updatePosition(self.position);
    }
}

fn getClosestHare(self: *Self) ?rl.Vector3 {
    var closestHare: ?rl.Vector3 = null;
    var closestDistance: f32 = 100000.0;
    for (game.modules.hares.array.items) |hare| {
        const distance = rlm.vector3DistanceSqr(hare.position, self.position);
        if (distance < closestDistance) {
            closestDistance = distance;
            closestHare = hare.position;
        }
    }
    if (closestDistance > CHASE_DISTANCE) return null;
    return closestHare;
}

fn getClosestFox(self: *Self, dist: f32) ?rl.Vector3 {
    var closestFox: ?rl.Vector3 = null;
    var closestDistance: f32 = 100000.0;
    for (game.modules.foxes.array.items) |fox| {
        const distance = rlm.vector3DistanceSqr(fox.position, self.position);
        if (distance < closestDistance) {
            closestDistance = distance;
            closestFox = fox.position;
        }
    }
    if (closestDistance > dist) return null;
    return closestFox;
}

pub fn draw(self: *const Self) void {
    var modelPosition = self.position;
    modelPosition.y += 1.0;
    rl.drawCube(self.position, 2.0, 2.0, 2.0, rl.Color.orange);

    self.target_handler.draw();
}
