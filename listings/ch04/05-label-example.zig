//! Listing 4.5 Using labels

const result: i32 = a: {
    const some_resource: Resource = .init();
    defer some_resource.deinit(); 

    if (some_resource.some_condition()) {
        break :a 0;
    }
    break :a 1;
};