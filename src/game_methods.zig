const std = @import("std");
const rl = @import("raylib");

pub fn On(comptime Game: type) type {
    return struct {
        pub fn update(self: *Game) !void {
            const ti: []const std.builtin.Type.StructField = @typeInfo(@TypeOf(self.modules)).Struct.fields;
            inline for (ti) |field| {
                if (@hasDecl(field.type, "update")) {
                    const res = @field(self.modules, field.name).update();
                    if (@typeInfo(@TypeOf(res)) == .ErrorUnion) try res;
                }
            }
        }

        pub fn draw(self: *Game) !void {
            if (self.camera == null) {
                return;
            }
            rl.beginMode3D(self.camera.?.*);
            defer rl.endMode3D();

            const ti: []const std.builtin.Type.StructField = @typeInfo(@TypeOf(self.modules)).Struct.fields;
            inline for (ti) |field| {
                if (@hasDecl(field.type, "draw")) {
                    const res = @field(self.modules, field.name).draw();
                    if (@typeInfo(@TypeOf(res)) == .ErrorUnion) try res;
                }
            }
        }
    };
}

fn IterableElem(comptime T: type) ?type {
    switch (@typeInfo(T)) {
        .Array => |info| return info.child,
        .Vector => |info| return info.child,
        .Pointer => |info| switch (info.size) {
            .One => switch (@typeInfo(info.child)) {
                .Array => |array_info| return array_info.child,
                .Vector => |vector_info| return vector_info.child,
                else => {},
            },
            .Slice => return info.child,
            else => {},
        },
        else => {},
    }
    return null;
}
