const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const rlgl = @import("rlgl");

const game = &@import("../Game.zig").game;

const Self = @This();

model: rl.Model,

pub fn init() !Self {
    const cubeMesh = rl.genMeshCube(1.0, 1.0, 1.0);
    const model = rl.loadModelFromMesh(cubeMesh);

    const vs = @embedFile("skybox.vs");
    const fs = @embedFile("skybox.fs");

    const shader = rl.loadShaderFromMemory(vs, fs);

    const mm_cubemap = @intFromEnum(rl.MaterialMapIndex.material_map_cubemap);
    const su_int = @intFromEnum(rl.ShaderUniformDataType.shader_uniform_int);
    rl.setShaderValue(shader, rl.getShaderLocation(shader, "environmentMap"), &[_]c_int{mm_cubemap}, su_int);
    rl.setShaderValue(shader, rl.getShaderLocation(shader, "doGamma"), &[_]c_int{0}, su_int);
    rl.setShaderValue(shader, rl.getShaderLocation(shader, "vflipped"), &[_]c_int{0}, su_int);

    model.materials[0].shader = shader;

    var image = rl.loadImage("resources/luthagsesplanaden.png");
    defer rl.unloadImage(image);

    image.setFormat(@intFromEnum(rl.PixelFormat.pixelformat_uncompressed_r8g8b8));

    model.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.material_map_cubemap)].texture = rl.loadTextureCubemap(image, @intFromEnum(rl.CubemapLayout.cubemap_layout_cross_four_by_three));

    return Self{ .model = model };
}

pub fn draw(self: *Self) !void {
    rlgl.rlDisableBackfaceCulling();
    defer rlgl.rlEnableBackfaceCulling();

    rlgl.rlDisableDepthMask();
    defer rlgl.rlEnableDepthMask();

    rl.drawModel(self.model, rl.Vector3.init(0, 0, 0), 1.0, rl.Color.white);
}
