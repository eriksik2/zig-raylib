const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const game = &@import("Game.zig").game;

const Self = @This();

movementSpeed: f32 = 0.15,
camera: rl.Camera3D,

pub fn update(self: *Self) !void {
    //rl.updateCamera(&self.camera, .camera_first_person);

    if (rl.isMouseButtonPressed(.mouse_button_left)) {
        const cubePos = rlm.vector3Add(self.camera.position, rlm.vector3Scale(self.camera.target, 0.0));
        try game.modules.cubes.array.append(.{
            .position = cubePos,
        });
    }

    self.updateMovement();
}

fn updateMovement(self: *Self) void {
    var movement = rl.Vector3.init(0.0, 0.0, 0.0);
    var rotation = rl.Vector3.init(0.0, 0.0, 0.0);

    if (rl.isKeyDown(.key_w)) {
        movement.x += self.movementSpeed;
    }
    if (rl.isKeyDown(.key_s)) {
        movement.x += -self.movementSpeed;
    }
    if (rl.isKeyDown(.key_a)) {
        movement.y += -self.movementSpeed;
    }
    if (rl.isKeyDown(.key_d)) {
        movement.y += self.movementSpeed;
    }
    if (rl.isKeyDown(.key_space)) {
        movement.z += self.movementSpeed;
    }
    if (rl.isKeyDown(.key_left_shift)) {
        movement.z += -self.movementSpeed;
    }

    const forward = rlm.vector3Normalize(rlm.vector3Subtract(self.camera.target, self.camera.position));
    const up = self.camera.up;
    const right = rlm.vector3Normalize(rlm.vector3CrossProduct(forward, up));

    self.camera.position = rlm.vector3Add(self.camera.position, rlm.vector3Scale(right, movement.y));
    self.camera.position = rlm.vector3Add(self.camera.position, rlm.vector3Scale(forward, movement.x));
    self.camera.position = rlm.vector3Add(self.camera.position, rlm.vector3Scale(up, movement.z));

    self.camera.target = rlm.vector3Add(self.camera.target, rlm.vector3Scale(right, movement.y));
    self.camera.target = rlm.vector3Add(self.camera.target, rlm.vector3Scale(forward, movement.x));
    self.camera.target = rlm.vector3Add(self.camera.target, rlm.vector3Scale(up, movement.z));

    const md = rl.getMouseDelta();

    const rotationSpeed = 0.5;
    rotation.x = md.x * rotationSpeed;
    rotation.y = md.y * rotationSpeed;

    rl.updateCameraPro(&self.camera, rl.Vector3.init(0.0, 0.0, 0.0), rotation, 0);
}
