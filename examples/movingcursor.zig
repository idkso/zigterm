const zt = @import("zigterm");

pub fn main() anyerror!void {
    try zt.initscr();
    try zt.raw();
    try zt.noecho();
    try zt.nocbreak();

    var c: u8 = undefined;
    var x: u16 = 0;
    var y: u16 = 0;
    while (true) {
        c = try zt.getch();
        switch (c) {
            'q' => break,
            'w' => y -= 1,
            'a' => x -= 1,
            's' => y += 1,
            'd' => x += 1,
            else => continue,
        }
        try zt.move(y, x);
    }

    try zt.refresh();
    try zt.endwin();
}
