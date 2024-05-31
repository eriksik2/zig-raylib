const std = @import("std");
const rl = @import("raylib");

const Game = @import("Game.zig");

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.disableCursor();
    rl.setTargetFPS(60);

    try Game.init();

    while (!rl.windowShouldClose()) {
        // Update

        try Game.game.update();

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        try Game.game.draw();

        rl.drawFPS(0, 0);
    }
}
