const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const znoise = @import("znoise");

const game = &@import("Game.zig").game;

const Self = @This();

position: rl.Vector3,
rotation: rl.Vector3,

size: Size,
heights: []u8,

model: rl.Model,

pub fn draw(self: *const Self) void {
    //const ident = rlm.matrixIdentity();
    const pt = rlm.matrixTranslate(self.position.x, self.position.y, self.position.z);
    const rt = rlm.matrixRotateXYZ(self.rotation);
    const transform = rlm.matrixMultiply(rt, pt);

    rl.drawMesh(self.model.meshes[0], self.model.materials[0], transform);
}

const Size = struct {
    x: usize,
    y: usize,
};

pub fn initRandom(opts: struct {
    seed: i32 = 40712,
    size: Size = .{ .x = 128, .y = 128 },
}) !Self {
    const gen = znoise.FnlGenerator{
        .seed = opts.seed,
        .frequency = 0.01,
        .noise_type = .opensimplex2,
        .rotation_type3 = .none,
        .fractal_type = .none,
        .octaves = 3,
        .lacunarity = 2.0,
        .gain = 0.5,
        .weighted_strength = 0.0,
        .ping_pong_strength = 2.0,
        .cellular_distance_func = .euclideansq,
        .cellular_return_type = .distance,
        .cellular_jitter_mod = 1.0,
        .domain_warp_type = .opensimplex2,
        .domain_warp_amp = 1.0,
    };

    const len = opts.size.x * opts.size.y;
    const heights = try game.allocator.alloc(u8, len);
    errdefer game.allocator.free(heights);

    for (0..opts.size.x) |x| {
        for (0..opts.size.y) |y| {
            const idx = coordToIdx(.{ .x = x, .y = y }, opts.size);
            var h = gen.noise2(@floatFromInt(x), @floatFromInt(y));
            h = (h + 1.0) / 2.0;
            heights[idx] = @intFromFloat(h * 255.0);
        }
    }

    const image = rl.Image{
        .data = heights.ptr,
        .width = @intCast(opts.size.x),
        .height = @intCast(opts.size.y),
        .mipmaps = 1,
        .format = .pixelformat_uncompressed_grayscale,
    };

    var mesh = rl.genMeshHeightmap(image, rl.Vector3.init(@floatFromInt(opts.size.x), 12, @floatFromInt(opts.size.y)));
    rl.genMeshTangents(&mesh);

    // Scale the image so that it looks nicer when used as texture
    const imgData = @as([*]u8, @ptrCast(image.data));
    for (0..len) |i| {
        imgData[i] = @divTrunc(imgData[i], 2) + 64;
    }

    const model = rl.loadModelFromMesh(mesh);
    model.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.material_map_albedo)].color = rl.Color.init(0, 255, 0, 255);
    model.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.material_map_albedo)].texture = rl.loadTextureFromImage(image);

    return Self{
        .position = rl.Vector3.init(0, -10, 0),
        .rotation = rl.Vector3.init(0, 0, 0),

        .size = opts.size,
        .heights = heights,

        .model = model,
    };
}

fn idxToCoord(idx: usize, size: Size) Size {
    return Size{ .x = idx % size.x, .y = idx / size.x };
}

fn coordToIdx(coord: Size, size: Size) usize {
    return coord.y * size.x + coord.x;
}
