const std = @import("std");
const rl = @import("raylib");

const Self = @This();

const State = enum {
    borderless,
    windowed,
};

state: State,

pub fn init(state: State) Self {
    var self = Self{
        .state = state,
    };
    self.setState(state);
    return self;
}

pub fn update(self: *Self) void {
    if (rl.isKeyPressed(.key_f11)) {
        switch (self.state) {
            .borderless => {
                self.setState(.windowed);
            },
            .windowed => {
                self.setState(.borderless);
            },
        }
    }
}

pub fn setState(self: *Self, state: State) void {
    const monitorId = rl.getCurrentMonitor();
    const monitorWidth = rl.getMonitorWidth(monitorId);
    const monitorHeight = rl.getMonitorHeight(monitorId);

    switch (state) {
        .borderless => {
            rl.setWindowState(.flag_window_undecorated);
            rl.setWindowPosition(0, 0);
            rl.setWindowSize(monitorWidth, monitorHeight);
        },
        .windowed => {
            rl.clearWindowState(.flag_window_undecorated);
            const windowedWidth = @divTrunc(monitorWidth * 2, 3);
            const windowedHeight = @divTrunc(monitorHeight * 2, 3);

            const windowedX = @divTrunc(monitorWidth, 2) - @divTrunc(windowedWidth, 2);
            const windowedY = @divTrunc(monitorHeight, 2) - @divTrunc(windowedHeight, 2);

            rl.setWindowSize(windowedWidth, windowedHeight);
            rl.setWindowPosition(windowedX, windowedY);
        },
    }
    self.state = state;
}
