const std = @import("std");
const Allocator = std.mem.Allocator;

pub const RecipeId = enum(c_int) { _ };

pub const RecipeBook = struct {
    const Self = @This();

    const Recipe = struct {
        name: [:0]const u8,
        author: [:0]const u8,
        instructions: [:0]const u8,
    };

    const Ingredient = struct {
        recipe_id: RecipeId,
        quantity: [:0]const u8,
        name: [:0]const u8,
    };

    string_arena: std.heap.ArenaAllocator,
    next_recipe_num: c_int = 0,
    recipes: std.AutoHashMapUnmanaged(RecipeId, Recipe),
    ingredients: std.ArrayList(Ingredient),

    fn init(ally: Allocator) Self {
        return .{
            .string_arena = .init(ally),
            .recipes = .empty,
            .ingredients = .empty,
        };
    }

    fn deinit(self: *Self, ally: Allocator) void {
        self.ingredients.deinit(ally);
        self.recipes.deinit(ally);
        self.string_arena.deinit();
    }

    fn dupeCString(self: *Self, cstr: [*:0]const u8) Allocator.Error![:0]const u8 {
        const arena_ally = self.string_arena.allocator();
        const slice = std.mem.span(cstr);
        return try arena_ally.dupeZ(u8, slice);
    }

    fn createRecipe(self: *Self, ally: Allocator, recipe: Recipe) Allocator.Error!RecipeId {
        const id: RecipeId = @enumFromInt(self.next_recipe_num);
        try self.recipes.put(ally, id, recipe);
        self.next_recipe_num += 1;
        return id;
    }

    const GetRecipeError = error{NonexistantRecipe};

    fn getRecipe(
        self: Self,
        id: RecipeId,
    ) GetRecipeError!Recipe {
        return self.recipes.get(id) orelse error.NonexistantRecipe;
    }

    fn addIngredient(
        self: *Self,
        ally: Allocator,
        recipe: RecipeId,
        quantity: [:0]const u8,
        name: [:0]const u8,
    ) Allocator.Error!void {
        try self.ingredients.append(ally, .{
            .recipe_id = recipe,
            .quantity = quantity,
            .name = name,
        });
    }

    fn deleteRecipe(self: *Self, recipe_id: RecipeId) void {
        _ = self.recipes.remove(recipe_id);

        var i: usize = 0;
        while (i < self.ingredients.items.len) {
            if (self.ingredients.items[i].recipe_id == recipe_id) {
                _ = self.ingredients.orderedRemove(i);
                continue;
            }
            i += 1;
        }
    }

    const IngredientIterator = struct {
        book: *const Self,
        recipe_id: RecipeId,
        index: usize = 0,

        fn next(iter: *@This()) ?Ingredient {
            return while (iter.index < iter.book.ingredients.items.len) {
                const ingredient = iter.book.ingredients.items[iter.index];
                iter.index += 1;
                if (ingredient.recipe_id == iter.recipe_id) {
                    return ingredient;
                }
            } else null;
        }
    };

    fn iterateIngredients(self: *const Self, recipe_id: RecipeId) IngredientIterator {
        return .{ .book = self, .recipe_id = recipe_id };
    }

    const JsonRepr = struct {
        const RecipeIdPair = struct {
            recipe_id: RecipeId,
            recipe: Recipe,
        };

        recipes: []const RecipeIdPair,
        ingredients: []const Ingredient,
        next_recipe_num: c_int,
    };

    fn toJson(self: Self, ally: Allocator, writer: *std.Io.Writer) !void {
        var recipe_id_pairs: std.ArrayList(JsonRepr.RecipeIdPair) = .empty;
        defer recipe_id_pairs.deinit(ally);

        var recipe_entries = self.recipes.iterator();
        while (recipe_entries.next()) |entry| {
            try recipe_id_pairs.append(ally, .{
                .recipe_id = entry.key_ptr.*,
                .recipe = entry.value_ptr.*,
            });
        }

        const repr: JsonRepr = .{
            .recipes = recipe_id_pairs.items,
            .ingredients = self.ingredients.items,
            .next_recipe_num = self.next_recipe_num,
        };

        var stringify: std.json.Stringify = .{ .writer = writer };
        try stringify.write(repr);
    }

    fn fromJson(ally: Allocator, reader: *std.Io.Reader) !Self {
        var arena: std.heap.ArenaAllocator = .init(ally);
        defer arena.deinit();
        const arena_ally = arena.allocator();

        var json_reader = std.json.Reader.init(arena_ally, reader);
        const repr = try std.json.parseFromTokenSourceLeaky(JsonRepr, arena_ally, &json_reader, .{});

        var self: Self = .init(ally);
        for (repr.recipes) |pair| {
            try self.recipes.put(ally, pair.recipe_id, .{
                .name = try self.dupeCString(pair.recipe.name),
                .author = try self.dupeCString(pair.recipe.author),
                .instructions = try self.dupeCString(pair.recipe.instructions),
            });
        }
        for (repr.ingredients) |ingredient| {
            try self.ingredients.append(ally, .{
                .recipe_id = ingredient.recipe_id,
                .quantity = try self.dupeCString(ingredient.quantity),
                .name = try self.dupeCString(ingredient.name),
            });
        }
        self.next_recipe_num = repr.next_recipe_num;

        return self;
    }
};

var gpa: std.heap.DebugAllocator(.{}) = .init;

export fn recipes_quit() void {
    _ = gpa.deinit();
    gpa = .init;
}

export fn recipe_book_create() ?*RecipeBook {
    const ally = gpa.allocator();
    const book = ally.create(RecipeBook) catch {
        return null;
    };
    book.* = .init(ally);

    return book;
}

export fn recipe_book_close(book: *RecipeBook) void {
    const ally = gpa.allocator();
    book.deinit(ally);
    ally.destroy(book);
}

const Success = enum(c_int) {
    ok = 0,

    out_of_memory = -1,
    nonexistant_recipe = -2,
    would_overflow = -3,
    file_error = -4,
    write_failed = -5,
};

const RecipeBookError = Allocator.Error || RecipeBook.GetRecipeError || std.Io.Writer.Error;

fn translateErr(e: RecipeBookError) Success {
    return switch (e) {
        error.OutOfMemory => .out_of_memory,
        error.NonexistantRecipe => .nonexistant_recipe,
        error.WriteFailed => .write_failed,
    };
}

export fn recipe_create(
    book: *RecipeBook,
    name: [*:0]const u8,
    author: [*:0]const u8,
    instructions: [*:0]const u8,
    out_recipe_id: *RecipeId,
) Success {
    const ally = gpa.allocator();

    out_recipe_id.* = book.createRecipe(ally, .{
        .name = book.dupeCString(name) catch |e| return translateErr(e),
        .author = book.dupeCString(author) catch |e| return translateErr(e),
        .instructions = book.dupeCString(instructions) catch |e| {
            return translateErr(e);
        },
    }) catch |e| return translateErr(e);

    return .ok;
}

export fn recipe_delete(book: *RecipeBook, recipe_id: RecipeId) void {
    book.deleteRecipe(recipe_id);
}

export fn recipe_add_ingredient(
    book: *RecipeBook,
    recipe_id: RecipeId,
    quantity: [*:0]const u8,
    name: [*:0]const u8,
) Success {
    const ally = gpa.allocator();
    book.addIngredient(
        ally,
        recipe_id,
        book.dupeCString(quantity) catch |e| return translateErr(e),
        book.dupeCString(name) catch |e| return translateErr(e),
    ) catch |e| return translateErr(e);

    return .ok;
}

const RetrievedIngredient = extern struct {
    quantity: [*:0]const u8,
    name: [*:0]const u8,
};

const RetrievedRecipe = extern struct {
    name: [*:0]const u8,
    author: [*:0]const u8,
    instructions: [*:0]const u8,
    ingredients: [*]const RetrievedIngredient,
    ingredient_count: usize,
};

export fn recipe_get(
    book: *const RecipeBook,
    recipe_id: RecipeId,
    buf_ptr: [*]u8,
    buf_len: usize,
    result: *RetrievedRecipe,
) Success {
    const buffer = buf_ptr[0..buf_len];
    var fba: std.heap.FixedBufferAllocator = .init(buffer);
    const buf_ally = fba.allocator();

    std.debug.print("getting recipe {any} {any} {*}\n", .{ book, recipe_id, buffer });

    const recipe = book.getRecipe(recipe_id) catch |e| {
        return translateErr(e);
    };

    var ingredients_copy: std.ArrayList(RetrievedIngredient) = .{};
    var ingredients = book.iterateIngredients(recipe_id);
    while (ingredients.next()) |ing| {
        ingredients_copy.append(buf_ally, .{
            .quantity = ing.quantity.ptr,
            .name = ing.name.ptr,
        }) catch return .would_overflow;
    }

    result.* = .{
        .name = recipe.name.ptr,
        .author = recipe.author.ptr,
        .instructions = recipe.instructions.ptr,
        .ingredients = ingredients_copy.items.ptr,
        .ingredient_count = ingredients_copy.items.len,
    };
    std.debug.print("got recipe {any}: {any}\n", .{ recipe_id, result.* });
    return .ok;
}

pub const RecipeIterator = extern struct {
    book: *const RecipeBook,
    recipe_num: c_int,
};

export fn recipe_iter_start(
    book: *const RecipeBook,
    out_iter: *RecipeIterator,
) void {
    out_iter.* = .{ .book = book, .recipe_num = 0 };
}

export fn recipe_iter_next(
    iter: *RecipeIterator,
    result: *RecipeId,
) bool {
    while (iter.recipe_num < iter.book.recipes.count()) {
        const next_id: RecipeId = @enumFromInt(iter.recipe_num);
        iter.recipe_num += 1;

        if (iter.book.recipes.contains(next_id)) {
            result.* = next_id;
            return true;
        }
    }

    return false;
}

export fn recipe_book_save(
    book: *const RecipeBook,
    filename: [*:0]const u8,
) Success {
    const ally = gpa.allocator();

    const filename_span = std.mem.span(filename);

    var file = std.fs.cwd().createFile(filename_span, .{}) catch {
        return .file_error;
    };
    defer file.close();
    var writer_buf: [1024]u8 = undefined;
    var file_writer = file.writer(&writer_buf);
    const writer = &file_writer.interface;

    book.toJson(ally, writer) catch |e| return translateErr(e);
    writer.flush() catch return .write_failed;

    return .ok;
}

export fn recipe_book_load(filename: [*:0]const u8) ?*RecipeBook {
    const filename_span = std.mem.span(filename);

    var file = std.fs.cwd().openFile(filename_span, .{
        .mode = .read_only,
    }) catch return null;
    defer file.close();
    var reader_buf: [1024]u8 = undefined;
    var file_reader = file.reader(&reader_buf);
    const reader = &file_reader.interface;

    const ally = gpa.allocator();
    const book = ally.create(RecipeBook) catch return null;
    book.* = RecipeBook.fromJson(ally, reader) catch return null;

    return book;
}

test {
    defer recipes_quit();

    const book = recipe_book_create() orelse {
        return error.TestFailed;
    };
    defer recipe_book_close(book);
}

test {
    defer recipes_quit();

    const book = recipe_book_create() orelse {
        return error.TestFailed;
    };
    defer recipe_book_close(book);

    var recipe_id: RecipeId = undefined;
    const create_res = recipe_create(
        book,
        "stew",
        "nobody",
        "this is a stew, it's made for you",
        &recipe_id,
    );
    try std.testing.expectEqual(.ok, create_res);

    const add_ing_res = recipe_add_ingredient(book, recipe_id, "1 oz", "love");
    try std.testing.expectEqual(.ok, add_ing_res);

    var json_buf: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&json_buf);

    try book.toJson(std.testing.allocator, &writer);

    var reader: std.Io.Reader = .fixed(writer.buffered());
    var book2: RecipeBook = try .fromJson(std.testing.allocator, &reader);
    defer book2.deinit(std.testing.allocator);

    var writer_buf: [1024]u8 = undefined;
    var file_writer = std.fs.File.stderr().writer(&writer_buf);
    const writer2 = &file_writer.interface;
    try book2.toJson(std.testing.allocator, writer2);
    try writer2.flush();
}
