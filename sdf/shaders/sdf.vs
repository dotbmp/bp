#version 430 core

out vec2 fragCoord;

void main() {
    fragCoord   = 2*vec2(gl_VertexID%2, gl_VertexID/2) - 1;
    gl_Position = vec4(fragCoord, 0.0, 1.0);
}
