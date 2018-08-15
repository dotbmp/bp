/*
 *  @Name:     txgen
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 13-08-2018 11:00:03 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 13-08-2018 22:39:31 UTC-5
 *  
 *  @Description:
 *  
 */

package txgen

import "core:os"

import "shared:odin-gl"



VERTEX_SHADER :: "shader.vx";



generate :: proc(shader: string, width, height: int, buf : []byte = nil) -> []byte {
    vao: u32;
    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao);

    fb: u32;
    gl.GenFramebuffers(1, &fb);
    gl.BindFramebuffer(gl.FRAMEBUFFER, fb);

    db: u32;
    gl.GenRenderbuffers(1, &db);
    gl.BindRenderbuffer(gl.RENDERBUFFER, db);
    gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT, i32(width), i32(height));
    gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, db);
    
    tx: u32;
    gl.GenTextures(1, &tx);
    gl.BindTexture(gl.TEXTURE_2D, tx);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, i32(width), i32(height), 0, gl.RGB, gl.UNSIGNED_BYTE, nil);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);

    program, _ := gl.load_shaders(VERTEX_SHADER, shader);

    gl.Viewport(0, 0, i32(width), i32(height));

    return buf;
}
