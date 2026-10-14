const std = @import("std");
const c = @import("c");

pub fn main() !void {
    const init_success = c.glfwInit();
    if (init_success == c.GLFW_FALSE) return error.GlfwInitFailed;
    defer c.glfwTerminate();

    const window = c.glfwCreateWindow(1280, 720, "learning opengl", null, null);
    if (window == null) return error.GlfwCreateWindowFailed;
    defer c.glfwDestroyWindow(window);

    while (c.GLFW_FALSE == c.glfwWindowShouldClose(window)) {
        c.glfwPollEvents();
    }
}
