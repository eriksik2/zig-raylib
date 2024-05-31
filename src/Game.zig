const std = @import("std");
const rl = @import("raylib");

const Game = @This();

const WindowManager = @import("WindowManager.zig");
const Player = @import("Player.zig");
const Cube = @import("Cube.zig");

pub var game: Game = .{};

modules: struct {
    windowManager: WindowManager = undefined,
    player: Player = undefined,
    cubes: [3]Cube = undefined,
} = .{},

camera: ?*rl.Camera3D = null,

pub fn init() void {
    game.modules.windowManager = WindowManager.init(.windowed);

    game.modules.player = .{
        .camera = .{
            .position = rl.Vector3.init(0, 0, 0),
            .target = rl.Vector3.init(0, 0, 1),
            .up = rl.Vector3.init(0, 1, 0),
            .fovy = 45.0,
            .projection = .camera_perspective,
        },
    };
    game.camera = &game.modules.player.camera;

    game.modules.cubes = [_]Cube{
        Cube{ .position = rl.Vector3.init(0, 0, 3) },
        Cube{ .position = rl.Vector3.init(0, -3, 3) },
        Cube{ .position = rl.Vector3.init(0, 3, 3) },
    };
}

pub usingnamespace @import("game_methods.zig").On(@This());
