const std = @import("std");

pub fn ArrayModule(comptime Type: type) type {
    const hasUpdate = @hasDecl(Type, "update");
    const hasDraw = @hasDecl(Type, "draw");
    return struct {
        const Self = @This();

        array: std.ArrayList(Type),

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .array = std.ArrayList(Type).init(alloc),
            };
        }

        pub usingnamespace if (hasUpdate) struct {
            pub fn update(self: *Self) !void {
                for (self.array.items) |*item| {
                    const res = item.update();
                    if (@typeInfo(@TypeOf(res)) == .ErrorUnion) try res;
                }
            }
        } else struct {};

        pub usingnamespace if (hasDraw) struct {
            pub fn draw(self: *Self) !void {
                for (self.array.items) |*item| {
                    const res = item.draw();
                    if (@typeInfo(@TypeOf(res)) == .ErrorUnion) try res;
                }
            }
        } else struct {};
    };
}
