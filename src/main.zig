const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const linux = std.os.linux;

pub const esc = "\x1B";
const csi = esc ++ "[";

var orig_termios: linux.termios = undefined;
var termios: linux.termios = undefined;

pub var cols: u16 = 5;
pub var rows: u16 = 5;

pub const attrs = enum(u8) {
    BOLD,
    UNDERLINED,
    REVERSED,
};

pub const colors = enum(u8) {
    RESET = 0,
    BLACK = 30,
    RED = 31,
    GREEN = 32,
    YELLOW = 33,
    BLUE = 34,
    MAGENTA = 35,
    CYAN = 36,
    WHITE = 37,
};

pub const cursors = enum(u8) {
    BLINK_BLOCK = 1,
    STEADY_BLOCK = 2,
    BLINK_UNDERLINE = 3,
    STEADY_UNDERLINE = 4,
    BLINK_BAR = 5,
    STEADY_BAR = 6,
    HIDE,
    SHOW,
};

pub fn color(id: colors) !void {
    try printw(csi ++ "{d}m", .{@enumToInt(id)});
}

pub fn initscr() !void {
    orig_termios = try std.os.tcgetattr(0);
    termios = orig_termios;
    try refresh();
    try move(0, 0);
}

pub fn raw() !void {
    termios.iflag &= ~(@as(u16, linux.BRKINT | linux.INPCK | linux.IXON));
    termios.cflag |= (linux.CS8);
    termios.lflag &= ~(@as(u16, linux.ICANON | linux.IEXTEN));
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, termios);
}

pub fn cursor(cur: cursors) !void {
    if(cur == cursors.HIDE) {
        try printw(csi ++ "?25l", .{});
    } else if(cur == cursors.SHOW) {
        try printw(csi ++ "?25h", .{});
    } else {
        try printw(csi ++ "{d} q", .{@enumToInt(cur)});
    }
}

pub fn noecho() !void {
    termios.lflag &= ~(@as(u16, linux.ECHO));
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, termios);
}

pub fn nocbreak() !void {
    termios.lflag &= ~(@as(u16, linux.ISIG));
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, termios);
}

pub fn cbreak () !void {
    termios.lflag &= (@as(u16, linux.ISIG));
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, termios);
}

pub fn echo() !void {
    termios.lflag &= (@as(u16, linux.ECHO));
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, termios);
}

pub fn noraw() !void {
    termios.lflag &= (@as(u16, linux.ICANON));
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, termios);
}

pub fn getch() !u8 {
    return try stdin.readByte();
}

pub fn move(row: u16, col: u16) !void {
    try stdout.print(csi ++ "{d};{d}H", .{row, col});
}

pub fn refresh() !void {
    try stdout.writeAll(csi ++ "2J");
    getWindowSize(&rows, &cols);
}

pub fn getWindowSize(a_rows: *u16, a_cols: *u16) void {
    var idk: linux.winsize = undefined;
    if (linux.syscall3(.ioctl, @bitCast(usize, @as(isize, 0)), linux.T.IOCGWINSZ, @ptrToInt(&idk)) != 0) {
        std.debug.panic("getting window size failed", .{});
        endwin();
    } else {
        a_rows.* = idk.ws_row;
        a_cols.* = idk.ws_col;
    }
}

pub fn clearTilEndLine() !void {
    try printw(csi ++ "0K", .{});
}

pub fn printw(comptime str: []const u8, args: anytype) !void {
    try stdout.print(str, args);
}

pub fn mvprintw(row: u16, col: u16, comptime str: []const u8, args: anytype) !void {
    try move(row, col);
    try printw(str, args);
}

pub fn attron(attr: attrs) !void {
    switch(attr) {
        attrs.BOLD => {
            try stdout.writeAll(csi ++ "1m");
        },
        attrs.REVERSED => {
            try stdout.writeAll(csi ++ "7m");
        },
        attrs.UNDERLINED => {
            try stdout.writeAll(csi ++ "4m");
        }
    }
}

pub fn attroff() !void {
    try stdout.writeAll(csi ++ "0m");
}

//fn removeAndReset(opt: u16) !void {
//    var new_termios: linux.termios = orig_termios;
//    for(enabled_opts.items) |i, item| {
//        if(item == opt) {
//            enabled_opts.orderedRemove(i);
//            continue;
//        }
//        new_termios.lflag &= ~(@as(u16, item));
//    }
//}

pub fn endwin() !void {
    try std.os.tcsetattr(0, linux.TCSA.FLUSH, orig_termios);
}
