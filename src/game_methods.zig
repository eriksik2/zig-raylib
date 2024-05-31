const std = @import("std");
const rl = @import("raylib");

pub fn On(comptime Game: type) type {
    return struct {
        pub fn update(self: *Game) void {
            const ti: []const std.builtin.Type.StructField = @typeInfo(@TypeOf(self.modules)).Struct.fields;
            inline for (ti) |field| {
                if (IterableElem(field.type)) |ElemType| {
                    const isArray = @typeInfo(field.type) == .Array;
                    if (@hasDecl(ElemType, "update")) {
                        const slice = if (isArray) &@field(self.modules, field.name) else @field(self.modules, field.name);
                        for (slice) |*elem| {
                            elem.update();
                        }
                    }
                } else if (@hasField(field.type, "items")) {
                    const ItemsType = std.meta.fieldInfo(field.type, .items).type;
                    if (IterableElem(ItemsType)) |ElemType| {
                        if (@hasDecl(ElemType, "update")) {
                            for (@field(self.modules, field.name)) |*elem| {
                                elem.update();
                            }
                        }
                    }
                } else if (@hasDecl(field.type, "update")) {
                    @field(self.modules, field.name).update();
                }
            }
        }

        pub fn draw(self: *Game) void {
            if (self.camera == null) {
                return;
            }
            rl.beginMode3D(self.camera.?.*);
            defer rl.endMode3D();

            const ti: []const std.builtin.Type.StructField = @typeInfo(@TypeOf(self.modules)).Struct.fields;
            inline for (ti) |field| {
                if (IterableElem(field.type)) |ElemType| {
                    const isArray = @typeInfo(field.type) == .Array;
                    if (@hasDecl(ElemType, "draw")) {
                        const slice = if (isArray) &@field(self.modules, field.name) else @field(self.modules, field.name);
                        for (slice) |*elem| {
                            elem.draw();
                        }
                    }
                } else if (@hasField(field.type, "items")) {
                    const ItemsType = std.meta.fieldInfo(field.type, .items).type;
                    if (IterableElem(ItemsType)) |ElemType| {
                        if (@hasDecl(ElemType, "draw")) {
                            for (@field(self.modules, field.name)) |*elem| {
                                elem.draw();
                            }
                        }
                    }
                } else if (@hasDecl(field.type, "draw")) {
                    @field(self.modules, field.name).draw();
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
