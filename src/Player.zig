const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const game = &@import("Game.zig").game;

const Self = @This();

state: enum {
    ground,
    air,
} = .air,
airVelocity: rl.Vector3 = rl.Vector3.init(0.0, 0.0, 0.0),
movementSpeed: f32 = 0.30,
camera: rl.Camera3D,

mode: enum {
    walk,
    fly,
} = .walk,

pub fn draw(self: *Self) !void {
    rl.endMode3D();
    defer rl.beginMode3D(self.camera);

    rl.drawText(try std.fmt.allocPrintZ(game.frame_allocator, "State: {s}", .{@tagName(self.state)}), 10, 20, 20, rl.Color.white);
}

pub fn update(self: *Self) !void {
    //rl.updateCamera(&self.camera, .camera_first_person);

    if (rl.isMouseButtonPressed(.mouse_button_left)) {
        const cubePos = rlm.vector3Add(self.camera.position, rlm.vector3Scale(self.camera.target, 0.0));
        try game.modules.cubes.array.append(.{
            .position = cubePos,
        });
    }

    if (rl.isKeyPressed(.key_v)) {
        if (self.mode == .walk) {
            self.mode = .fly;
            self.airVelocity = rl.Vector3.init(0.0, 2.5, 0.0);
        } else {
            self.mode = .walk;
        }
    }

    self.updatePhysics();
    self.updateMovement();
}

fn updatePhysics(self: *Self) void {
    const PLAYER_HEIGHT = 5.0;
    const GRAVITY = rl.Vector3.init(0.0, -0.1, 0.0);

    const shouldCollide = self.mode == .walk;
    const shouldFall = self.mode == .walk;

    if (shouldFall) {
        self.airVelocity = rlm.vector3Add(self.airVelocity, GRAVITY);
        if (self.airVelocity.y < -1.5) {
            self.airVelocity.y = -1.5;
        }
    }
    self.airVelocity = rlm.vector3Scale(self.airVelocity, 0.9);

    self.camera.position = rlm.vector3Add(self.camera.position, self.airVelocity);
    self.camera.target = rlm.vector3Add(self.camera.target, self.airVelocity);

    if (shouldCollide) {
        const groundY = game.modules.world.getY(self.camera.position.x, self.camera.position.z);
        const footPosition = rlm.vector3Add(self.camera.position, rl.Vector3.init(0.0, -PLAYER_HEIGHT, 0.0));
        if (footPosition.y <= groundY) {
            self.state = .ground;
            self.airVelocity = rl.Vector3.init(0.0, 0.0, 0.0);
            const camTargetDiff = self.camera.target.y - self.camera.position.y;
            self.camera.position.y = groundY + PLAYER_HEIGHT;
            self.camera.target.y = groundY + PLAYER_HEIGHT + camTargetDiff;
        } else {
            self.state = .air;
        }
    } else {
        self.state = .air;
    }
}

fn updateMovement(self: *Self) void {
    const forward = rlm.vector3Normalize(rlm.vector3Subtract(self.camera.target, self.camera.position));
    const up = self.camera.up;
    const right = rlm.vector3Normalize(rlm.vector3CrossProduct(forward, up));

    var movement = rl.Vector3.init(0.0, 0.0, 0.0);
    var rotation = rl.Vector3.init(0.0, 0.0, 0.0);

    var ms = self.movementSpeed;
    const sprintMultiplier = 2.3;
    if (rl.isKeyDown(.key_left_shift)) {
        ms = ms * sprintMultiplier;
    }

    if (rl.isKeyDown(.key_w)) {
        movement.x += ms;
    }
    if (rl.isKeyDown(.key_s)) {
        movement.x += -ms;
    }
    if (rl.isKeyDown(.key_a)) {
        movement.y += -ms;
    }
    if (rl.isKeyDown(.key_d)) {
        movement.y += ms;
    }
    if (self.mode == .walk) {
        if (rl.isKeyPressed(.key_space)) {
            self.airVelocity.y = 2.0;
        }
    } else {
        if (rl.isKeyDown(.key_space)) {
            movement.z += ms;
        }
    }
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
