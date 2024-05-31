const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const Self = @This();

position: rl.Vector3,
rotation: rl.Vector3,
mesh: rl.Mesh,
material: rl.Material,

pub fn draw(self: *const Self) void {
    const pt = rlm.matrixTranslate(self.position.x, self.position.y, self.position.z);
    const rt = rlm.matrixRotateXYZ(self.rotation);
    const transform = rlm.matrixMultiply(rt, pt);
    rl.drawMesh(self.mesh, self.material, transform);
}

pub fn initIceland() Self {
    const image = rl.loadImage("iceland_heightmap.png");
    defer rl.unloadImage(image);

    var mesh = rl.genMeshHeightmap(image, rl.Vector3.init(16, 8, 16));
    rl.genMeshTangents(&mesh);

    const material = rl.loadMaterialDefault();
    material.maps[@intFromEnum(rl.MaterialMapIndex.material_map_albedo)].color = rl.Color.init(255, 0, 255, 255);

    return Self{
        .position = rl.Vector3.init(0, 0, 0),
        .rotation = rl.Vector3.init(0, 90, 0),
        .mesh = mesh,
        .material = material,
    };
}
