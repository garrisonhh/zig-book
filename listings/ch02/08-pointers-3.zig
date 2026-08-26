//! Listing 2.8 Coercing a constant pointer to a regular pointer

var x: i32 = 0;
const x_mutable_ptr = &x; // (1) This is inferred to be a *i32.
const x_const_ptr: *const i32 = x_mutable_ptr;  // (2) Coercing *i32 into *const i32.