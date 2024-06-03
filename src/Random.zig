const std = @import("std");

const Self = @This();

rnd: std.rand.DefaultPrng,

pub fn init(seed: u64) Self {
    return .{
        .rnd = std.rand.DefaultPrng.init(seed),
    };
}

pub fn float(self: *Self) f32 {
    return self.rnd.random().float(f32);
}
