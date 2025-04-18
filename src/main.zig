const std = @import("std");
const lib = @import("dgen_lib");
const builtin = @import("builtin");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.heap.page_allocator.free(args);

    const args_slc = args[1..];
    if (args_slc.len == 0) {
        try print_help(args[0]);
        return;
    }

    var raw = false;
    var cpf = false;
    var cnpj = false;

    for (args_slc) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try print_help(args[0]);
            return;
        } else if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "--raw")) {
            raw = true;
        } else if (std.mem.eql(u8, arg, "--cpf")) {
            cpf = true;
        } else if (std.mem.eql(u8, arg, "--cnpj")) {
            cnpj = true;
        } else {
            try std.io.getStdErr().writer().print("Error: Unknown argument '{s}'\n", .{arg});
            return;
        }
    }

    var runned = false;
    if (cpf) {
        const res = try gen_cpf();
        defer std.heap.page_allocator.free(res);
        try print_cpf(res, raw);
        runned = true;
    }

    if (cnpj) {
        const res = try gen_cnpj();
        defer std.heap.page_allocator.free(res);
        try print_cnpj(res, raw);
        runned = true;
    }

    if (!runned) {
        try print_help(args[0]);
    }
}

fn gen_cpf() ![]u8 {
    var rb = try random_buff(11);

    var mult: u8 = 10;
    var result: u32 = 0;
    for (0..9) |i| {
        result += @as(u32, rb[i]) * mult;
        mult -= 1;
    }
    var calc: u32 = (result * 10) % 11;
    const d1: u8 = if (calc >= 10) 0 else @intCast(calc);
    rb[9] = d1;

    mult = 11;
    result = 0;
    for (0..10) |i| {
        result += @as(u32, rb[i]) * mult;
        mult -= 1;
    }
    calc = (result * 10) % 11;
    const d2: u8 = if (calc >= 10) 0 else @intCast(calc);
    rb[10] = d2;

    return rb;
}

fn gen_cnpj() ![]u8 {
    var rb = try random_buff(14);

    var mult: u8 = 5;
    var result: u32 = 0;
    for (0..12) |i| {
        if (i == 4) {
            mult = 9;
        }
        result += @as(u32, rb[i]) * mult;
        mult -= 1;
    }
    var calc = result % 11;
    const d1: u8 = if (calc < 2) 0 else @intCast(11 - calc);
    rb[12] = d1;

    mult = 6;
    result = 0;
    for (0..13) |i| {
        if (i == 5) {
            mult = 9;
        }
        result += @as(u32, rb[i]) * mult;
        mult -= 1;
    }
    calc = result % 11;
    const d2: u8 = if (calc < 2) 0 else @intCast(11 - calc);
    rb[13] = d2;

    return rb;
}

fn print_cpf(cpf: []u8, raw: bool) !void {
    const stdout = std.io.getStdOut().writer();
    var sep: u8 = 0;
    for (cpf, 0..) |digit, i| {
        if (!raw) {
            sep = if (i == 2 or i == 5) '.' else 0;
            if (i == 8) {
                sep = '-';
            }
        }
        try stdout.print("{c}", .{digit + '0'});
        if (sep != 0) try stdout.print("{c}", .{sep});
    }
    try stdout.print("\n", .{});
}

fn print_cnpj(cnpj: []u8, raw: bool) !void {
    const stdout = std.io.getStdOut().writer();
    var sep: u8 = 0;
    for (cnpj, 0..) |digit, i| {
        if (!raw) {
            sep = if (i == 1 or i == 4) '.' else 0;
            if (i == 7) {
                sep = '/';
            }
            if (i == 11) {
                sep = '-';
            }
        }
        try stdout.print("{c}", .{digit + '0'});
        if (sep != 0) try stdout.print("{c}", .{sep});
    }
    try stdout.print("\n", .{});
}

fn random_buff(len: usize) ![]u8 {
    var allocator = std.heap.page_allocator;
    const str = try allocator.alloc(u8, len);
    for (str) |*digit| {
        digit.* = std.crypto.random.int(u8) % 10;
    }
    return str;
}

fn print_help(pname: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    const txt =
        \\Usage:
        \\  {s} [command]
        \\Commands:
        \\ --cpf        Generate CPF
        \\ --cnpj       Generate CNPJ
        \\ -r, --raw     Output numbers without formatting
        \\ -h, -help    Show this help message
        \\
    ;
    try stdout.print(txt, .{pname});
}
