/*
 *  @Name:     sdf
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-02-2018 11:04:23 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 19-10-2018 09:23:26 UTC-5
 *  
 *  @Description:
 *  
 */

package sdf

using import "core:math"
import "core:os"

import "shared:odin-gl"
import "shared:odin-glfw"


Color :: Vec4;


WHITE := Color{1, 1, 1, 1};
BLACK := Color{0, 0, 0, 1};

RED   := Color{1, 0, 0, 1};
GREEN := Color{0, 1, 0, 1};
BLUE  := Color{0, 0, 1, 1};

YELLOW := Color{1, 1, 0, 1};
PURPLE := Color{1, 0, 1, 1};
TEAL   := Color{0, 1, 1, 1};


  VERTEX_SHADER :: "shaders/sdf.vs";
FRAGMENT_SHADER :: "shaders/sdf.fs";


_program: u32;

when os.OS == "windows" {
    _ftime: os.File_Time;
    _vtime: os.File_Time;
}

_vao: u32;
_buffer: u32;
_dirty := true;


Operation :: enum u32 {
    Invalid = 0,

    Draw    = 1,
    Queue   = 2,
}

Code :: enum u32 {
    Invalid      = 0,

    Intersect    = 1,
    Substract    = 2,
    Unify        = 3,
    Repeat       = 4,

    Disk         = 5,
    Ring         = 6,
    Box          = 7,
    Rounded_Box  = 8,
    Rect         = 9,
    Rounded_Rect = 10,
    Line         = 11,
    Segment      = 12,
}

Command :: struct {
    operation: Operation,
    code:      Code,
    id0, id1:  u32,
    params:    [16]f32,
}


commands := make([dynamic]Command, 0, 1024);


Disk :: struct {
    pos:      Vec2,
    diameter: f32,
    color:    Color,
}

disk :: proc[disk_type, disk_args];

disk_type :: inline proc(using disk: Disk) -> int {
    return disk_args(pos, diameter, color);
}

disk_args :: proc(pos: Vec2, diameter: f32, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Disk;
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = diameter;

    return append(&commands, command) - 1;
}


Ring :: struct {
    pos:       Vec2,
    diameter:  f32,
    thickness: f32,
    color:     Color,
}

ring :: proc[ring_type, ring_args];

ring_type :: inline proc(using ring: Ring) -> int {
    return ring_args(pos, diameter, thickness, color);
}

ring_args :: proc(pos: Vec2, diameter, thickness: f32, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Ring;
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = diameter;
    command.params[7] = thickness;

    return append(&commands, command) - 1;
}


Box :: struct {
    pos:   Vec2,
    dim:   Vec2,
    color: Color,
}

box :: proc[box_type, box_args];

box_type :: inline proc(using box: Box) -> int {
    return box_args(pos, dim, color);
}

box_args :: proc(pos: Vec2, dim: Vec2, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    if dim.x < 0 {
        pos.x += dim.x;
        dim.x = -dim.x;
    }

    if dim.y < 0 {
        pos.y += dim.y;
        dim.y = -dim.y;
    }

    command: Command;
    command.operation = operation;
    command.code      = Code.Box;
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = dim.x;
    command.params[7] = dim.y;

    return append(&commands, command) - 1;
}


Rect :: struct {
    pos:       Vec2,
    dim:       Vec2,
    thickness: f32,
    color:     Color,
}

rect :: proc[rect_type, rect_args];

rect_type :: inline proc(using rect: Rect) -> int {
    return rect_args(pos, dim, thickness, color);
}

rect_args :: proc(pos: Vec2, dim: Vec2, thickness: f32, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Rect;
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = dim.x;
    command.params[7] = dim.y;
    command.params[8] = thickness;

    return append(&commands, command) - 1;
}


RBox :: struct {
    pos:       Vec2,
    dim:       Vec2,
    radius:    f32,
    thickness: f32,
    color:     Color,
}

rbox :: proc[rbox_type, rbox_args];

rbox_type :: inline proc(using rbox: RBox) -> int {
    return rbox_args(pos, dim, radius, color);
}

rbox_args :: proc(pos: Vec2, dim: Vec2, radius: f32, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Rounded_Box;
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = dim.x;
    command.params[7] = dim.y;
    command.params[8] = radius;

    return append(&commands, command) - 1;
}


RRect :: struct {
    pos:       Vec2,
    dim:       Vec2,
    radius:    f32,
    thickness: f32,
    color:     Color,
}

rrect :: proc[rrect_type, rrect_args];

rrect_type :: proc(using rrect: RRect) -> int {
    return rrect_args(pos, dim, radius, thickness, color);
}

rrect_args :: proc(pos: Vec2, dim: Vec2, radius, thickness: f32, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Rounded_Rect;
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = dim.x;
    command.params[7] = dim.y;
    command.params[8] = radius;
    command.params[9] = thickness;

    return append(&commands, command) - 1;
}


line :: proc(vec2: Vec2, dim: Vec2, radius: f32) -> int {return 0;};

intersect :: proc(a, b: int, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Intersect;
    command.id0       = u32(a);
    command.id1       = u32(b);
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;

    return append(&commands, command);
}

substract :: proc(a, b: int, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Substract;
    command.id0       = u32(a);
    command.id1       = u32(b);
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;

    return append(&commands, command);
}

unify :: proc(a, b: int, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Unify;
    command.id0       = u32(a);
    command.id1       = u32(b);
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;

    return append(&commands, command);   
}

repeat :: proc(i: u32, pos: Vec2, spread: Vec2, color := Color{1, 1, 1, 1}, operation := Operation.Draw) -> int {
    _dirty = true;

    command: Command;
    command.operation = operation;
    command.code      = Code.Repeat;
    command.id0       = u32(i);
    command.params[0] = color.x;
    command.params[1] = color.y;
    command.params[2] = color.z;
    command.params[3] = color.w;
    command.params[4] = pos.x;
    command.params[5] = pos.y;
    command.params[6] = spread.x;
    command.params[7] = spread.y;

    return append(&commands, command);
}


init :: proc() -> () {
    gl.GenVertexArrays(1, &_vao);
    gl.BindVertexArray(_vao);

    gl.GenBuffers(1, &_buffer);

    _program, _ = gl.load_shaders(VERTEX_SHADER, FRAGMENT_SHADER);

    when os.OS == "windows" {
        _vtime = os.last_write_time_by_name(VERTEX_SHADER);
        _ftime = os.last_write_time_by_name(FRAGMENT_SHADER);
    }
}


draw :: proc(w, h: int) {
    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, _buffer);
    
    if _dirty && len(commands) > 0 {
        gl.BufferData(gl.SHADER_STORAGE_BUFFER, cap(commands) * size_of(Command), &commands[0], gl.DYNAMIC_DRAW);
        gl.BindBufferRange(gl.SHADER_STORAGE_BUFFER, 0, _buffer, 0, cap(commands) * size_of(Command));

        _dirty = false;
    }

    when os.OS == "windows" {
    ftime := os.last_write_time_by_name(VERTEX_SHADER);
        _program, _ftime, _vtime, _ = gl.update_shader_if_changed(VERTEX_SHADER, FRAGMENT_SHADER, _program, _ftime, _vtime);
    }

    gl.UseProgram(_program);

    gl.Uniform2f (gl.get_uniform_location(_program, "iResolution"), f32(w), f32(h));
    gl.Uniform1ui(gl.get_uniform_location(_program, "iBufLen"),     u32(len(commands)));

    gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4);

    ///////////////////////////////////////////////////////////////
    ////                                                       ////
    //// @todo(bpunsky): don't update all data every frame pls ////
    /**/                                                       /**/
    /**/                  clear(&commands);                    /**/
    /**/                                                       /**/
    ///////////////////////////////////////////////////////////////
}
