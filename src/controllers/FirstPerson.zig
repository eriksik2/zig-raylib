const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const game = &@import("Game.zig").game;

const Self = @This();

const State = union(enum) {
    ground: Ground,
    air: void,

    pub const Ground = struct {
        pos: rl.Vector3,
        slope: rl.Vector3,
    };
};

movementSpeed: f32 = 0.30,
position: rl.Vector3 = rl.Vector3.init(0.0, 0.0, 0.0),
forward: rl.Vector3 = rl.Vector3.init(0.0, 0.0, 1.0),

pub fn update(self: *Self) !void {
    const forward = self.forward;
    const up = rl.Vector3.init(0.0, 1.0, 0.0);
    const right = rlm.vector3Normalize(rlm.vector3CrossProduct(forward, up));

    var mov = rl.Vector3.init(0.0, 0.0, 0.0);

    var ms = self.movementSpeed;
    const sprintMultiplier = 2.3;
    if (rl.isKeyDown(.key_left_shift)) {
        ms = ms * sprintMultiplier;
    }

    if (rl.isKeyDown(.key_w)) {
        mov.x += ms;
    }
    if (rl.isKeyDown(.key_s)) {
        mov.x += -ms;
    }
    if (rl.isKeyDown(.key_a)) {
        mov.y += -ms;
    }
    if (rl.isKeyDown(.key_d)) {
        mov.y += ms;
    }

    const positionDelta = rlm.vector3Add(
        rlm.vector3Add(
            rlm.vector3Scale(right, mov.y),
            rlm.vector3Scale(forward, mov.x),
        ),
        rlm.vector3Scale(up, mov.z),
    );

    const md = rl.getMouseDelta();
    const rotationSpeed = 0.5;

    const yaw = md.x * rotationSpeed;
    const pitch = md.y * rotationSpeed;

    const newForward = rlm.vector3RotateByAxisAngle(
        rlm.vector3RotateByAxisAngle(forward, up, yaw),
        right,
        pitch,
    );

    self.position = rlm.vector3Add(self.position, positionDelta);
    self.forward = newForward;
}
