//! Listing 2.20 Your pizza order

pub const Pizza = struct { // (1) A pizza with some delicious defaults
    mushrooms: bool = true,
    olives: bool = true,
    artichoke: bool = true,
    pepperoni: bool = false,
    canned_tuna: bool = false,
};

pub fn main() void {
    const garrisons_favorite: Pizza = .{}; // (2) My favorite pizza, with the default options.
    const pepperoni: Pizza = .{ // (3) A pepperoni pizza, with some modified fields.
        .mushrooms = false,
        .olives = false,
        .artichoke = false,
        .pepperoni = true,
    };

    // ... order pizza ...
}