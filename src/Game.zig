const std = @import("std");
const rl = @import("raylib");

const Game = @This();

const ArrayModule = @import("array_module.zig").ArrayModule;

const WindowManager = @import("WindowManager.zig");
const Skybox = @import("skybox/Skybox.zig");
const World = @import("World.zig");
const Player = @import("Player.zig");
const Pawn = @import("Pawn.zig");
const Cube = @import("Cube.zig");
const Fox = @import("ecosystem/Fox.zig");
const Hare = @import("ecosystem/Hare.zig");

const Random = @import("Random.zig");

pub var game: Game = undefined;

modules: struct {
    windowManager: WindowManager,
    skybox: Skybox,
    world: World,
    player: Player,
    foxes: ArrayModule(Fox),
    hares: ArrayModule(Hare),
    cubes: ArrayModule(Cube),
},

camera: ?*rl.Camera3D = null,

rnd: Random = Random.init(40713),

allocators: struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}) = .{},
    frame_allocator: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator),
} = .{},

allocator: std.mem.Allocator,
frame_allocator: std.mem.Allocator,

pub fn init() !void {
    game = .{
        .modules = undefined,
        .allocator = undefined,
        .frame_allocator = undefined,
    };
    game.allocator = game.allocators.gpa.allocator();
    game.frame_allocator = game.allocators.frame_allocator.allocator();

    game.modules = .{
        .windowManager = WindowManager.init(.{
            .state = .windowed,
            .mouse = .locked,
        }),
        .skybox = try Skybox.init(),
        .world = try World.initRandom(.{}),
        .player = undefined,
        //.pawn = Pawn.init(.{
        //    .position = rl.Vector3.init(40, 1, 40),
        //}),
        .foxes = ArrayModule(Fox).init(game.allocator),
        .hares = ArrayModule(Hare).init(game.allocator),
        .cubes = ArrayModule(Cube).init(game.allocator),
    };

    game.modules.player = .{
        .camera = .{
            .position = rl.Vector3.init(35, 30, 35),
            .target = rl.Vector3.init(36, 29, 36),
            .up = rl.Vector3.init(0, 1, 0),
            .fovy = 75.0,
            .projection = .camera_perspective,
        },
    };
    game.camera = &game.modules.player.camera;

    for (0..100) |_| {
        const x = game.modules.world.position.x + 128 + game.rnd.float() * 128;
        const z = game.modules.world.position.z + 128 + game.rnd.float() * 128;
        try game.modules.hares.array.append(Hare.init(.{
            .position = rl.Vector3.init(x, 1, z),
        }));
    }

    for (0..100) |_| {
        const x = game.modules.world.position.x + game.rnd.float() * 128;
        const z = game.modules.world.position.z + game.rnd.float() * 128;
        try game.modules.foxes.array.append(Fox.init(.{
            .position = rl.Vector3.init(x, 1, z),
        }));
    }
}

pub fn postDraw(self: *Game) !void {
    var nIdle: usize = 0;
    var nLookingFood: usize = 0;
    var nLookingWater: usize = 0;
    var nLookingSocial: usize = 0;
    var nAvoidingSocial: usize = 0;
    for (self.modules.foxes.array.items) |fox| {
        switch (fox.state) {
            .idleWandering => nIdle += 1,
            .lookingForFood => nLookingFood += 1,
            .lookingForWater => nLookingWater += 1,
            .lookingForSocial => nLookingSocial += 1,
            .avoidingSocial => nAvoidingSocial += 1,
        }
    }
    rl.endMode3D();
    defer rl.beginMode3D(self.camera.?.*);

    var text = try std.fmt.allocPrintZ(self.frame_allocator, "N idle: {d}", .{nIdle});
    rl.drawText(text, 50, 10, 20, rl.Color.blue);

    text = try std.fmt.allocPrintZ(self.frame_allocator, "N looking food: {d}", .{nLookingFood});
    rl.drawText(text, 50, 30, 20, rl.Color.blue);

    text = try std.fmt.allocPrintZ(self.frame_allocator, "N looking water: {d}", .{nLookingWater});
    rl.drawText(text, 50, 50, 20, rl.Color.blue);

    text = try std.fmt.allocPrintZ(self.frame_allocator, "N looking social: {d}", .{nLookingSocial});
    rl.drawText(text, 50, 70, 20, rl.Color.blue);

    text = try std.fmt.allocPrintZ(self.frame_allocator, "N avoiding social: {d}", .{nAvoidingSocial});
    rl.drawText(text, 50, 90, 20, rl.Color.blue);

    text = try std.fmt.allocPrintZ(self.frame_allocator, "N foxes: {d}", .{self.modules.foxes.array.items.len});
    rl.drawText(text, 50, 110, 20, rl.Color.blue);
}

pub usingnamespace @import("game_methods.zig").On(@This());
