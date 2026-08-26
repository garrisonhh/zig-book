const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

// book notes:
//
// - I should talk about the reality of window/input libraries and opengl loaders
//   - without the use of hefty frameworks, graphics and desktop application
//     programming demands a lot of systems knowledge
//     - every operating system has a different relationship with the graphical
//       desktop environment. Windows and OS X have proprietary desktop
//       environments, and Linux users can choose between the ancient X11 and
//       young Wayland
//     - individual desktop environments have their own quirks. they have
//       different runtime models, different limitations and error conditions.
//       for application development, operating systems and desktop environments
//       provide different mechanisms for input. abstracting over any one of
//       these things is hard, and abstracting over all of them is a monumental
//       task. this is why we need amazing libraries like glfw!
//     - further complicating the situation, OpenGL is implemented by drivers (...)
//
// - why glfw?
//   - we need a glfw loader
//   - is easy to setup (I think I can rely on readers to do it themselves). it's
//     a mature library, distributed
//   - it's one of raylib's backends!
//   - glfw is super stable: reported errors are never fatal, as long as init
//     succeeded the library will stay in a safe state until terminated (from
//     docs)
//
// - why specifically opengl 3.3? an older version of an older version?
//   - yes, vulkan is newer, but it is complicated and is not supported
//     seamlessly everywhere like opengl 3.3. unless you are trying to support
//     extraordinarily new and niche hardware, or are building graphics software
//     intended for 10 years from now, opengl 3.3 is still the best choice for
//     its good flexibility and almost ubiquitous support
//
// - why glad?
//   - we still need an opengl loader once we have a context
//   - glad is minimal, it works well, it is widely supported, and glfw's
//     developers suggest it

const vertex_shader_source =
    \\#version 330 core
    \\
    \\in vec2 pos;
    \\
    \\void main() {
    \\    gl_Position = vec4(pos, 0.0, 1.0);
    \\}
;
const fragment_shader_source =
    \\#version 330 core
    \\
    \\out vec4 fragColor;
    \\
    \\void main() {
    \\    fragColor = vec4(1.0, 0.0, 1.0, 1.0);
    \\}
;

fn glfwErrorCallback(code: c_int, desc: [*c]const u8) callconv(.c) void {
    std.debug.print("glfw error {d}: {s}\n", .{ code, desc });
}

fn compileShader(kind: c_uint, source: [:0]const u8) !c_uint {
    const shader = c.glCreateShader(kind);
    errdefer c.glDeleteShader(shader);

    c.glShaderSource(shader, 1, @ptrCast(&source), null);
    c.glCompileShader(shader);

    var compile_success: c_int = undefined;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &compile_success);
    if (compile_success == 0) {
        var info_buf: [512]u8 = undefined;
        var info_len: c.GLsizei = undefined;
        c.glGetShaderInfoLog(shader, info_buf.len, &info_len, &info_buf);
        const info = info_buf[0..@intCast(info_len)];

        std.debug.print("shader compilation failed: {s}\n", .{info});

        return error.ShaderCompilationFailed;
    }

    return shader;
}

fn compileProgram(
    vertex_src: [:0]const u8,
    fragment_src: [:0]const u8,
) error{ ShaderCompilationFailed, ShaderLinkingFailed }!c_uint {
    const program = c.glCreateProgram();
    errdefer c.glDeleteProgram(program);

    const vertex_shader = try compileShader(c.GL_VERTEX_SHADER, vertex_src);
    defer c.glDeleteShader(vertex_shader);
    const fragment_shader = try compileShader(c.GL_FRAGMENT_SHADER, fragment_src);
    defer c.glDeleteShader(fragment_shader);

    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);

    var link_success: c_int = undefined;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &link_success);
    if (link_success == 0) {
        var info_buf: [512]u8 = undefined;
        var info_len: c.GLsizei = undefined;
        c.glGetProgramInfoLog(program, info_buf.len, &info_len, &info_buf);
        const info = info_buf[0..@intCast(info_len)];

        std.debug.print("shader linking failed: {s}\n", .{info});

        return error.ShaderLinkingFailed;
    }

    return program;
}

pub fn main() !void {
    if (c.GLFW_FALSE == c.glfwInit()) return error.GlfwInitFailed;
    defer c.glfwTerminate();

    _ = c.glfwSetErrorCallback(&glfwErrorCallback);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE); // only necessary on mac

    const window = c.glfwCreateWindow(1280, 720, "gl triangle", null, null);
    defer c.glfwDestroyWindow(window);

    if (window == null) return error.GlfwCreateWindowFailed;

    c.glfwMakeContextCurrent(window);
    const glad_res = c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress));
    if (glad_res == 0) return error.GladLoadGlLoaderFailed;

    const shader_program = try compileProgram(vertex_shader_source, fragment_shader_source);
    defer c.glDeleteProgram(shader_program);

    var vao: c_uint = undefined;
    c.glGenVertexArrays(1, &vao);
    defer c.glDeleteVertexArrays(1, &vao);

    const triangle = [_]f32{
        -0.5, -0.5,
        0.5,  -0.5,
        0.0,  0.5,
    };

    var triangle_vbo: c_uint = undefined;
    c.glGenBuffers(1, &triangle_vbo);
    defer c.glDeleteBuffers(1, &triangle_vbo);

    // load triangle into the buffer
    {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, triangle_vbo);
        defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

        c.glBufferData(
            c.GL_ARRAY_BUFFER,
            triangle.len * @sizeOf(f32),
            @ptrCast(&triangle),
            c.GL_STATIC_DRAW,
        );
    }

    {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, triangle_vbo);
        defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

        c.glBindVertexArray(vao);
        defer c.glBindVertexArray(0);

        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @ptrFromInt(0));
        c.glEnableVertexAttribArray(0);
    }

    while (c.GLFW_FALSE == c.glfwWindowShouldClose(window)) {
        c.glClearColor(0.1, 0.2, 0.2, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        {
            c.glBindVertexArray(vao);
            defer c.glBindVertexArray(0);

            c.glUseProgram(shader_program);
            defer c.glUseProgram(0);

            c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
