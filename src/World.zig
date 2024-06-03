const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const znoise = @import("znoise");

const game = &@import("Game.zig").game;

const VERTEX_PER_UNIT = 2;

const Self = @This();

position: rl.Vector3,
rotation: rl.Vector3,
scale: rl.Vector3,
size: Size,
heights: []u8,

model: rl.Model,

pub fn draw(self: *const Self) void {
    //const ident = rlm.matrixIdentity();
    const pt = rlm.matrixTranslate(self.position.x, self.position.y, self.position.z);
    const rt = rlm.matrixRotateXYZ(self.rotation);
    const transform = rlm.matrixMultiply(rt, pt);

    rl.drawMesh(self.model.meshes[0], self.model.materials[0], transform);

    //var playerPos = game.modules.player.camera.position;
    //playerPos.y = self.getY(playerPos.x, playerPos.z);
    //rl.drawSphere(playerPos, 0.2, rl.Color.red);

    //for (0..self.size.x) |x| {
    //    for (0..self.size.z) |z| {
    //        const idx = coordToIdx(.{ .x = x, .z = z }, self.size);
    //        const wx = self.position.x + @as(f32, @floatFromInt(x)) * VERTEX_PER_UNIT;
    //        const wz = self.position.z + @as(f32, @floatFromInt(z)) * VERTEX_PER_UNIT;
    //        const h: f32 = @floatFromInt(self.heights[idx]);
    //        const wy = self.position.y + h * (self.scale.y / 255.0);
    //        const loc = rl.Vector3.init(wx, wy, wz);
    //        rl.drawCube(loc, 0.1, 0.1, 0.1, rl.Color.red);
    //    }
    //}
    //rl.drawGrid(2000, 1);
}

pub fn getY(self: *const Self, x: f32, z: f32) f32 {
    const sizeX = @as(f32, @floatFromInt(self.size.x));
    const sizeZ = @as(f32, @floatFromInt(self.size.z));
    const locX = (x - self.position.x) / VERTEX_PER_UNIT;
    const locZ = (z - self.position.z) / VERTEX_PER_UNIT;

    if (locX < 0 or locZ < 0 or locX + 1 >= sizeX or locZ + 1 >= sizeZ) {
        return 0;
    }
    const x0: u32 = @intFromFloat(locX);
    const z0: u32 = @intFromFloat(locZ);
    const x1 = x0 + 1;
    const z1 = z0 + 1;

    const xf = locX - @as(f32, @floatFromInt(x0));
    const zf = locZ - @as(f32, @floatFromInt(z0));

    const h00: f32 = @floatFromInt(self.heights[coordToIdx(.{ .x = x0, .z = z0 }, self.size)]);
    const h01: f32 = @floatFromInt(self.heights[coordToIdx(.{ .x = x0, .z = z1 }, self.size)]);
    const h10: f32 = @floatFromInt(self.heights[coordToIdx(.{ .x = x1, .z = z0 }, self.size)]);
    const h11: f32 = @floatFromInt(self.heights[coordToIdx(.{ .x = x1, .z = z1 }, self.size)]);

    const xh0 = h00 * (1.0 - xf) + h10 * xf;
    const xh1 = h01 * (1.0 - xf) + h11 * xf;
    const zh = xh0 * (1.0 - zf) + xh1 * zf;

    const y = self.position.y + zh * (self.scale.y / 255.0);

    //rl.endMode3D();
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "py: {d}", .{game.modules.player.camera.position.y}) catch unreachable, 10, 130, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "locZ: {d}", .{locZ}) catch unreachable, 10, 160, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "x0: {d}", .{x0}) catch unreachable, 10, 200, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "z0: {d}", .{z0}) catch unreachable, 10, 230, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "h00: {d}", .{h00}) catch unreachable, 10, 260, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "h01: {d}", .{h01}) catch unreachable, 10, 290, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "h10: {d}", .{h10}) catch unreachable, 10, 320, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "h11: {d}", .{h11}) catch unreachable, 10, 350, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "zh: {d}", .{zh}) catch unreachable, 10, 380, 30, rl.Color.white);
    //rl.drawText(std.fmt.allocPrintZ(game.frame_allocator, "y: {d}", .{y}) catch unreachable, 10, 410, 30, rl.Color.white);
    //rl.beginMode3D(game.camera.?.*);

    return y;
}

const Size = struct {
    x: usize,
    z: usize,
};

pub fn initRandom(opts: struct {
    seed: i32 = 40712,
    size: Size = .{ .x = 128, .z = 128 },
}) !Self {
    const gen = znoise.FnlGenerator{
        .seed = opts.seed,
        .frequency = 0.002,
        .noise_type = .opensimplex2,
        .rotation_type3 = .none,
        .fractal_type = .fbm,
        .octaves = 5,
        .lacunarity = 3.25,
        .gain = 0.25,
        .weighted_strength = 0.0,
        .ping_pong_strength = 2.0,
        .cellular_distance_func = .euclideansq,
        .cellular_return_type = .distance,
        .cellular_jitter_mod = 1.0,
        .domain_warp_type = .opensimplex2,
        .domain_warp_amp = 1.0,
    };

    const len = opts.size.x * opts.size.z;
    const heights = try game.allocator.alloc(u8, len);
    errdefer game.allocator.free(heights);

    for (0..opts.size.x) |x| {
        for (0..opts.size.z) |z| {
            const idx = coordToIdx(.{ .x = x, .z = z }, opts.size);
            var h = gen.noise2(@floatFromInt(x), @floatFromInt(z));
            h = (h + 1.0) / 2.0;
            heights[idx] = @intFromFloat(h * 255.0);
        }
    }

    const imageHeights = try game.allocator.dupe(u8, heights);
    errdefer game.allocator.free(imageHeights);

    const image = rl.Image{
        .data = imageHeights.ptr,
        .width = @intCast(opts.size.x),
        .height = @intCast(opts.size.z),
        .mipmaps = 1,
        .format = .pixelformat_uncompressed_grayscale,
    };

    const scale = rl.Vector3.init(@floatFromInt(opts.size.x * VERTEX_PER_UNIT), 208.0, @floatFromInt(opts.size.z * VERTEX_PER_UNIT));
    var mesh = rl.genMeshHeightmap(image, scale);
    rl.genMeshTangents(&mesh);

    // Scale the image so that it looks nicer when used as textures
    const imgData = @as([*]u8, @ptrCast(image.data));
    for (0..len) |i| {
        var float: f32 = @floatFromInt(imgData[i]);
        float = float / 255.0;
        float = 1.0 - float;
        float = float * float;
        float = 1.0 - float;
        float = 0.4 + float * 0.5;
        imgData[i] = @intFromFloat(float * 255.0);
    }

    const model = rl.loadModelFromMesh(mesh);
    model.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.material_map_albedo)].color = rl.Color.init(136, 166, 90, 255);
    model.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.material_map_albedo)].texture = rl.loadTextureFromImage(image);

    return Self{
        .position = rl.Vector3.init(0, 0, 0),
        .rotation = rl.Vector3.init(0, 0, 0),
        .scale = scale,

        .size = opts.size,
        .heights = heights,

        .model = model,
    };
}

fn idxToCoord(idx: usize, size: Size) Size {
    return Size{ .x = idx % size.x, .z = idx / size.x };
}

fn coordToIdx(coord: Size, size: Size) usize {
    return coord.z * size.x + coord.x;
}
