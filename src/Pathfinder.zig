const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const Self = @This();

const game = &@import("Game.zig").game;

const min_distance = 0.1;
const min_target_distance = 2.0;

origin: rl.Vector3,
target: ?rl.Vector3 = null,

path_origin: ?rl.Vector3 = null,
path_target: ?rl.Vector3 = null,
path: ?[]rl.Vector3 = null,
path_progress: u32 = 0,

astar: AStar,

pub fn init(pos: rl.Vector3) Self {
    return .{
        .origin = pos,
        .astar = AStar.init(game.frame_allocator),
    };
}
pub fn draw(self: *const Self) void {
    if (self.path == null) return;
    var lastPoint: ?rl.Vector3 = if (self.path.?.len == 1) self.origin else null;
    for (self.path.?[0..self.path_progress]) |point| {
        const raised = rl.Vector3{ .x = point.x, .y = point.y + 0.1, .z = point.z };
        if (lastPoint) |last| rl.drawLine3D(last, raised, rl.Color.green);
        lastPoint = raised;
    }
    for (self.path.?[self.path_progress..]) |point| {
        const raised = rl.Vector3{ .x = point.x, .y = point.y + 0.1, .z = point.z };
        if (lastPoint) |last| rl.drawLine3D(last, raised, rl.Color.red);
        lastPoint = raised;
    }

    if (self.target) |target| {
        rl.drawSphere(target, 0.1, rl.Color.red);
    }
    //rl.drawSphere(self.origin, 0.1, rl.Color.green);

    //if (self.astar) |astar| astar.draw();
}

pub fn updateOrigin(self: *Self, newOrigin: rl.Vector3) void {
    const oldOrigin = self.origin;
    self.origin = newOrigin;
    if (self.target == null) return;
    if (self.path == null) return;

    const npp = (self.getNextPathPoint() catch unreachable).?;
    const newDistance = rlm.vector3DistanceSqr(newOrigin, npp);
    if (newDistance < min_distance) {
        self.increasePathProgress();
    } else {
        const oldDistance = rlm.vector3DistanceSqr(oldOrigin, npp);
        if (newDistance > oldDistance) {
            self.clearPath();
        }
    }
}

pub fn updateTarget(self: *Self, newTarget: rl.Vector3) void {
    self.target = newTarget;
    if (self.path_target) |oldTarget| {
        if (rlm.vector3DistanceSqr(oldTarget, newTarget) > min_distance) {
            self.clearPath();
        }
    }
}

pub fn getNextPathPoint(self: *Self) !?rl.Vector3 {
    if (self.target == null) {
        return null;
    }
    if (self.path == null) {
        if (rlm.vector3DistanceSqr(self.origin, self.target.?) < min_target_distance) {
            return null;
        }
        try self.calculatePath();
        if (self.path == null) return null;
    }
    return self.path.?[self.path_progress];
}

fn increasePathProgress(self: *Self) void {
    if (self.path == null) unreachable;
    self.path_progress += 1;
    if (self.path_progress >= self.path.?.len) {
        self.clearPath();
    }
}

fn clearPath(self: *Self) void {
    if (self.path == null) unreachable;
    game.allocator.free(self.path.?);
    self.path = null;
    self.path_progress = 0;
    self.path_origin = null;
    self.path_target = null;
}

fn calculatePath(self: *Self) !void {
    if (self.target == null) unreachable;
    if (self.path != null) unreachable;

    var newPath = try self.astar.findPath(game.allocator, self.origin, self.target.?);

    if (newPath == null) {
        newPath = try game.allocator.alloc(rl.Vector3, 1);
        newPath.?[0] = self.target.?;
    }

    self.path = newPath;
    self.path_progress = 0;
    self.path_origin = self.origin;
    self.path_target = self.target.?;
}

const AStar = struct {
    const Pos = struct {
        x: i32,
        z: i32,
    };
    const Node = struct {
        prev: ?*const Node = null,
        pos: Pos,
        g: f32 = 0, // accumulated cost
        h: f32 = 0, // heuristic cost
    };
    fn lessThan(context: void, a: *const Node, b: *const Node) std.math.Order {
        _ = context;
        return std.math.order(a.g + a.h, b.g + b.h);
    }

    const SeenSet = std.HashMap(*const Node, void, struct {
        pub fn hash(self: @This(), item: *const Node) u64 {
            _ = self; // autofix
            const ux: u32 = @bitCast(item.pos.x);
            const uz: u32 = @bitCast(item.pos.z);
            return @as(u64, @intCast(ux)) << 32 | @as(u64, @intCast(uz));
        }
        pub fn eql(self: @This(), item1: *const Node, item2: *const Node) bool {
            _ = self; // autofix
            return item1.pos.x == item2.pos.x and item1.pos.z == item2.pos.z;
        }
    }, 80);

    const FrontierQueue = std.PriorityQueue(*const Node, void, lessThan);

    frame_alloc: std.mem.Allocator,
    frontier: FrontierQueue,
    seen: SeenSet,
    max_sqr_distance_from_origin: u32 = 20,

    pub fn init(frame_alloc: std.mem.Allocator) AStar {
        return AStar{
            .frontier = FrontierQueue.init(frame_alloc, {}),
            .seen = SeenSet.init(frame_alloc),
            .frame_alloc = frame_alloc,
        };
    }

    pub fn deinit(self: *AStar) void {
        self.frontier.deinit();
        self.seen.deinit();
    }

    fn navDist(a: Pos, b: Pos) u32 {
        return @max(@abs(a.x - b.x), @abs(a.z - b.z));
    }
    fn worldToNav(world: rl.Vector3) Pos {
        return .{
            .x = @intFromFloat(world.x / 4.0),
            .z = @intFromFloat(world.z / 4.0),
        };
    }

    fn navToWorld(nav: Pos) rl.Vector3 {
        const x: f32 = @floatFromInt(nav.x * 4);
        const z: f32 = @floatFromInt(nav.z * 4);
        return .{
            .x = x,
            .y = game.modules.world.getY(x, z),
            .z = z,
        };
    }

    pub fn draw(self: *const AStar) void {
        var it = self.seen.keyIterator();
        while (it.next()) |keyPtr| {
            const key = keyPtr.*;
            rl.drawCube(rl.Vector3{ .x = @floatFromInt(key.x), .y = 0, .z = @floatFromInt(key.z) }, 0.5, 0.5, 0.5, rl.Color{ .r = 0, .g = 0, .b = 255, .a = 255 });
        }
    }

    pub fn findPath(self: *AStar, alloc: std.mem.Allocator, start: rl.Vector3, target: rl.Vector3) !?[]rl.Vector3 {
        const navStart = worldToNav(start);
        const navTarget = worldToNav(target);

        if (navDist(navStart, navTarget) > self.max_sqr_distance_from_origin) {
            return null;
        }

        self.seen = SeenSet.init(self.frame_alloc);
        self.frontier = FrontierQueue.init(self.frame_alloc, {});

        const startNode = try self.frame_alloc.create(Node);
        startNode.* = Node{ .prev = null, .pos = navStart, .g = 0, .h = 0 };

        try self.frontier.add(startNode);

        var iters: u32 = 0;
        while (self.frontier.removeOrNull()) |current| {
            if (current.pos.x == navTarget.x and current.pos.z == navTarget.z) {
                const path = try self.reconstructPath(alloc, current);
                return path;
            }

            const neighbors = try self.getNeighbors(self.frame_alloc, navStart, current, navTarget);
            for (neighbors) |neighbor| {
                try self.seen.put(neighbor, {});
                try self.frontier.add(neighbor);
            }
            iters += 1;
            if (iters > 2000) {
                std.log.warn("A* iteration limit reached, stopping.", .{});
                return null;
            }
        }

        return null;
    }

    fn getNeighbors(self: *AStar, frame_alloc: std.mem.Allocator, start: Pos, current: *const Node, target: Pos) ![]*const Node {
        const neighbors = try frame_alloc.alloc(*const Node, 8);
        var neighborsCount: u32 = 0;

        for ([_]i32{ -1, 0, 1 }) |dx| {
            for ([_]i32{ -1, 0, 1 }) |dz| {
                if (dx == 0 and dz == 0) {
                    continue;
                }

                const x = current.pos.x + dx;
                const z = current.pos.z + dz;
                const pos = Pos{ .x = x, .z = z };

                if (navDist(pos, start) > self.max_sqr_distance_from_origin) {
                    continue;
                }

                if (self.seen.get(&Node{ .pos = pos })) |_| {
                    continue;
                }

                const distTarget: f32 = @floatFromInt(navDist(pos, target));
                const distTargetCost = distTarget * 1.75;

                // World cost
                const currentWorld = navToWorld(current.pos);
                const nodeWorld = navToWorld(pos);
                var worldCost = (nodeWorld.y - currentWorld.y) * 1.0;
                if (worldCost < -3.0) worldCost *= -1.25;
                // end World cost

                const cost = 1 + distTargetCost + worldCost;
                const neighbor = try frame_alloc.create(Node);
                neighbor.* = Node{
                    .prev = current,
                    .pos = pos,
                    .g = current.g + cost,
                    .h = cost,
                };

                neighbors[neighborsCount] = neighbor;
                neighborsCount += 1;
            }
        }

        return neighbors[0..neighborsCount];
    }

    fn reconstructPath(self: *AStar, alloc: std.mem.Allocator, node: *const Node) ![]rl.Vector3 {
        _ = self; // autofix
        var path = std.ArrayList(rl.Vector3).init(alloc);
        errdefer path.deinit();

        try path.append(navToWorld(node.pos));

        var activeNode: ?*const Node = node;
        while (activeNode) |nn| : (activeNode = nn.prev) {
            try path.append(navToWorld(nn.pos));
        }

        std.mem.reverse(rl.Vector3, path.items);

        return try path.toOwnedSlice();
    }
};
