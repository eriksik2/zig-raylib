const std = @import("std");
const rl = @import("raylib");

const Game = @This();

const ArrayModule = @import("array_module.zig").ArrayModule;

const WindowManager = @import("WindowManager.zig");
const Skybox = @import("skybox/Skybox.zig");
const World = @import("World.zig");
const Player = @import("Player.zig");
const Cube = @import("Cube.zig");

pub var game: Game = undefined;

modules: struct {
    windowManager: WindowManager,
    skybox: Skybox,
    world: World,
    player: Player,
    cubes: ArrayModule(Cube),
},

camera: ?*rl.Camera3D = null,

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
        .windowManager = WindowManager.init(.windowed),
        .skybox = try Skybox.init(),
        .world = try World.initRandom(.{}),
        .player = undefined,
        .cubes = ArrayModule(Cube).init(game.allocator),
    };

    game.modules.player = .{
        .camera = .{
            .position = rl.Vector3.init(5, 0, 5),
            .target = rl.Vector3.init(6, -0.1, 6),
            .up = rl.Vector3.init(0, 1, 0),
            .fovy = 65.0,
            .projection = .camera_perspective,
        },
    };
    game.camera = &game.modules.player.camera;
}

pub usingnamespace @import("game_methods.zig").On(@This());
