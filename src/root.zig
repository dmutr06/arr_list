const std = @import("std");
const testing = std.testing;

const INIT_ARR_CAP: usize = 16;

pub fn ArrList(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        data: []T,
        size: usize,
        cap: usize,

        const Self = @This();

        pub fn initWithCap(cap: usize, allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .data = allocator.alloc(T, cap) catch unreachable,
                .size = 0,
                .cap = cap,
            };
        }

        pub fn init(allocator: std.mem.Allocator) Self {
            return initWithCap(INIT_ARR_CAP, allocator);
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.data);
        }

        pub fn push(self: *Self, item: T) void {
            if (self.size >= self.cap)
                self.changeCap(self.cap * 2);
            self.data[self.size] = item;
            self.size += 1;
        }

        pub fn get(self: Self, idx: usize) ?*T {
            if (self.size <= idx) return null;

            return &self.data[idx];
        }

        pub fn pop(self: *Self) ?T {
            if (self.size == 0) return null;

            self.size -= 1;
            return self.data[self.size];
        }

        pub fn remove(self: *Self, idx: usize) ?T {
            if (self.size <= idx) return null;
            if (idx == self.size - 1) return self.pop();

            const val = self.data[idx];

            @memcpy(self.data[idx .. self.size - 1], self.data[idx + 1 .. self.size]);
            self.size -= 1;
            return val;
        }

        pub fn resize(self: *Self, new_size: usize) void {
            if (new_size >= self.cap)
                self.changeCap(new_size * 2);

            self.size = new_size;
        }

        fn changeCap(self: *Self, new_cap: usize) void {
            const prev_data = self.data;
            self.cap = new_cap;

            self.data = self.allocator.alloc(T, self.cap) catch unreachable;
            if (self.size > 0)
                @memcpy(self.data[0..self.size], prev_data);
            self.allocator.free(prev_data);
        }
    };
}

test "ArrList init" {
    const list = ArrList(u8).init(std.testing.allocator);
    defer list.deinit();
    try testing.expect(list.cap == INIT_ARR_CAP);
}

test "ArrList push" {
    var list = ArrList(u8).init(std.testing.allocator);
    defer list.deinit();
    list.push(5);

    try testing.expect(list.data[0] == 5);
}

test "ArrList get" {
    var list = ArrList(u8).init(std.testing.allocator);
    defer list.deinit();
    list.push(5);

    try testing.expect(list.get(0).?.* == 5);
    try testing.expect(list.get(1) == null);
}

test "ArrList remove" {
    var list = ArrList(u8).init(std.testing.allocator);
    defer list.deinit();

    list.push(5);
    list.push(6);
    list.push(10);

    const removed_item = list.remove(1).?;
    try testing.expect(removed_item == 6);
    try testing.expect(list.get(0).?.* == 5);
    try testing.expect(list.get(1).?.* == 10);
}

test "ArrList resize" {
    var list = ArrList(u8).init(std.testing.allocator);
    defer list.deinit();

    list.resize(5);

    try testing.expect(list.size == 5);
    list.get(4).?.* = 10;

    try testing.expect(list.get(4).?.* == 10);
}
