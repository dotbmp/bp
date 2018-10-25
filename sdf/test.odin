/*
 *  @Name:     test
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-02-2018 11:04:31 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 18-10-2018 20:42:05 UTC-5
 *  
 *  @Description:
 *  
 */

package sdf

import "core:fmt"
using import "core:math"
import "core:mem"
import "core:strings"

import "shared:odin-gl"
import "shared:odin-glfw"



WINDOW_TITLE  :: "SDF Sandbox";

WINDOW_WIDTH  :: 1600;
WINDOW_HEIGHT :: 900;

OPENGL_MAJOR  :: 4;
OPENGL_MINOR  :: 3;

ANTIALIASING  :: 4;

VSYNC         :: true;

FRAME_TIMINGS :: true;



Object :: struct {
    code: Code,

    pos:  Vec2,
    vel:  Vec2,
    acc:  Vec2,
    mass: f32,

    color: Color,

    fixed: bool,

    diameter:  f32,
    thickness: f32,
}

new_ring :: proc(pos : Vec2, diameter, thickness : f32, mass : f32, color : Color, fixed := false) -> Object {
    return Object{
        code  = Code.Ring,
        pos   = pos,
        mass  = mass,
        color = color,
        fixed = fixed,

        diameter  = diameter,
        thickness = thickness,
    };
}

new_disk :: proc(pos : Vec2, diameter : f32, mass : f32, color : Color, fixed := false) -> Object {
    return Object{
        code  = Code.Disk,
        pos   = pos,
        mass  = mass,
        color = color,
        fixed = fixed,

        diameter = diameter,
    };
}



main :: proc() {
    window := glfw.init_helper(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, OPENGL_MAJOR, OPENGL_MINOR, ANTIALIASING, VSYNC);

    gl.load_up_to(OPENGL_MAJOR, OPENGL_MINOR, glfw.set_proc_address);
    
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    init();

    gl.ClearColor(0.1, 0.1, 0.15, 1.0);

    boxes : [dynamic]Box;

    box : Box;
    box.pos = -(Vec2{WINDOW_WIDTH, WINDOW_HEIGHT}/2);
    box.dim = Vec2{300, 100};
    box.color = RED;
    
    layout :: proc(pos : Vec2, dim : Vec2, x : Vec2) -> (res : Vec2) {
        return;
    } 

    for i in 0..2 {
        box.pos.x += box.dim.x + 20;
        tmp := box.pos.y;

        for j in 0..5 {
            box.pos.y += box.dim.y + 20;

            append(&boxes, box);
        }

        box.pos.y = tmp;
    }

    default_objects := [?]Object{
        new_ring(Vec2{   0,    0}, 70, 10, 70000, GREEN,  true),
        new_disk(Vec2{ 200,  -20}, 20,     100,   RED),
        new_disk(Vec2{-300,  250}, 10,     100,   YELLOW),
        new_disk(Vec2{ 460,  -92}, 10,     100,   TEAL),
        new_disk(Vec2{-100,   30}, 15,     100,   BLUE),
        new_disk(Vec2{-100, -100}, 10,     100,   PURPLE),
    };

    objects : [dynamic]Object;
    append(&objects, ..default_objects[:]);

    old_left : i32;
    old_right : i32;

    size := f32(5.0);

    for !glfw.WindowShouldClose(window) {
        if glfw.GetKey(window, glfw.KEY_ESCAPE) {
            glfw.SetWindowShouldClose(window, true);
        }

        when FRAME_TIMINGS do glfw.calculate_frame_timings(window);

        gl.Clear(gl.COLOR_BUFFER_BIT);

        time := cast(f32) glfw.GetTime(); 

        x, y := glfw.GetCursorPos(window);
        cursor := Vec2{f32(x) - (WINDOW_WIDTH/2), -(f32(y) - (WINDOW_HEIGHT/2))};

        if glfw.GetKey(window, glfw.KEY_SPACE) {
            clear(&objects);
            append(&objects, ..default_objects[:]);
        }

        left  := glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_LEFT);
        right := glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_RIGHT);

        if left == glfw.PRESS {
            size *= 1.1;
            ring(cursor, size, size * 0.2, WHITE);
        }
        else if left == glfw.RELEASE {
            if old_left == glfw.PRESS {
                append(&objects, new_ring(cursor, size, size * 0.2, size, WHITE));
                size = 5.0;
            }
        }

        if right == glfw.RELEASE && old_right == glfw.PRESS {
            arr := (^mem.Raw_Dynamic_Array)(&objects);
            if arr.len > 0 {
                arr.len -= 1;
            }
        }

        old_left  = left;
        old_right = right;

        dt :: 1.0/60.0*0.1;
        GRAVITY :: 60.0;
        
        for k in 0..9 {

            // force calculations
            for _, i in objects {
                obj := &objects[i];
                obj.acc = 0;

                for _, j in objects {
                    obj2 := &objects[j];

                    if i != j {
                        obj.acc += -GRAVITY * obj2.mass / math.pow(math.length(obj.pos - obj2.pos), 3) * (obj.pos - obj2.pos);
                    }
                }
            }

            for _, i in objects {
                obj := &objects[i];
                obj.pos, obj.vel = obj.pos + obj.vel*dt, obj.vel + obj.acc*dt;
            }

            // collision response
            // update each particle
            for _, i in objects {
                obj := &objects[i];
                for _, j in objects {
                    if j <= i do continue;

                    obj2 := &objects[j];

                    // velocities relative to particle i
                    dv := obj.vel - obj2.vel;
                    dr := obj.pos - obj2.pos;

                    if math.length(dr) - obj.diameter/2 - obj2.diameter/2.0 < 0.0 && math.dot(dv, dr) < 0.0 {
                        // only collide when intersecting and moving towards each other
                        obj.vel -= 2.0*obj2.mass / (obj.mass + obj2.mass) * math.dot(dv, dr) / math.dot(dr, dr) * dr;
                        obj2.vel += 2.0*obj.mass / (obj.mass + obj2.mass) * math.dot(dv, dr) / math.dot(dr, dr) * dr;
                    }
                }
            }
        }

        // draw
        for obj in objects {
            if obj.code == Code.Ring {
                ring(obj.pos, obj.diameter, obj.thickness, obj.color);
            }
            else {
                disk(obj.pos, obj.diameter, obj.color);
            }
        }

        draw(WINDOW_WIDTH, WINDOW_HEIGHT);

        glfw.SwapBuffers(window);
        glfw.PollEvents();
    }
}