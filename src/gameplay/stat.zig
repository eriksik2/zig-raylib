const std = @import("std");

pub fn StatConfig(comptime T: type) type {
    return struct {
        pub const isInt = @typeInfo(T) == .Int;

        max: ?T = if (isInt) null else 1,
        min: ?T = if (isInt) null else 0,
    };
}

pub fn Stat(comptime T: type, comptime config: StatConfig(T)) type {
    return struct {
        const Self = @This();

        value: T,
        delta: T = 0,

        pub fn update(self: *Self) void {
            if (comptime (StatConfig(T).isInt and config.max == null and config.min == null)) {
                self.value = self.value +| self.delta;
            } else {
                self.value = self.value + self.delta;
            }

            if (comptime config.max) |max| {
                if (self.value > max) {
                    self.value = max;
                }
            }
            if (comptime config.min) |min| {
                if (self.value < min) {
                    self.value = min;
                }
            }
        }
    };
}
