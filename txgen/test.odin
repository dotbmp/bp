/*
 *  @Name:     test
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-08-2018 11:01:28 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 14-08-2018 17:12:29 UTC-5
 *  
 *  @Description:
 *  
 */

package txgen

import "core:fmt"
import "core:mem"
import "core:os"

import gl   "shared:odin-gl"
import glfw "shared:odin-glfw"

import bmp "bp:bitmap"



WINDOW_TITLE :: "txgen test";

WIDTH  :: 600;
HEIGHT :: 600;

OPENGL_MAJOR :: 4;
OPENGL_MINOR :: 3;

ANTIALIASING :: 0;

VSYNC :: true;



FRAGMENT_SHADER :: "shader.fx";

BITMAP :: "test.bmp";



main :: proc() {
    fmt.println("yo");
    window := glfw.init_helper(WIDTH, HEIGHT, WINDOW_TITLE, OPENGL_MAJOR, OPENGL_MINOR, ANTIALIASING, VSYNC);

    gl.load_up_to(OPENGL_MAJOR, OPENGL_MINOR, glfw.set_proc_address);

    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    gl.ClearColor(0.0, 0.0, 0.0, 1.0);

    vao: u32;
    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao);

    buf := make([]u32, WIDTH * HEIGHT);
    defer delete(buf);

    generate(FRAGMENT_SHADER, WIDTH, HEIGHT, mem.slice_to_bytes(buf[:]));
    bmp.save(BITMAP, WIDTH, HEIGHT, buf[:]);

    program, ok := gl.load_shaders(VERTEX_SHADER, FRAGMENT_SHADER);

    vtime := os.last_write_time_by_name(VERTEX_SHADER);
    ftime := os.last_write_time_by_name(FRAGMENT_SHADER);

    if ok {
        // gl.UseProgram(program);

        for !glfw.WindowShouldClose(window) {
            if glfw.GetKey(window, glfw.KEY_ESCAPE) {
                glfw.SetWindowShouldClose(window, true);
            }

            gl.Clear(gl.COLOR_BUFFER_BIT);

            program, ftime, vtime, _ = gl.update_shader_if_changed(VERTEX_SHADER, FRAGMENT_SHADER, program, ftime, vtime);
            gl.UseProgram(program);

            time := glfw.GetTime();

            gl.Uniform2f(gl.get_uniform_location(program, "iResolution"), WIDTH, HEIGHT);
            gl.Uniform1f(gl.get_uniform_location(program, "iTime"), f32(time));
            gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4);

            glfw.SwapBuffers(window);
            glfw.PollEvents();
        }
    }
    else {
        fmt.println_err("Shader failed to load.");
    }
}
