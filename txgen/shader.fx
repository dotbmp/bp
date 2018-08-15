#version 430 core

in  vec4 fragCoord;
out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;

void main() {
    vec2 p = (fragCoord.xy + 1.0) * 0.5;
    fragColor = vec4(p.x, p.y, 1.0-((p.x+p.y)*0.5), 1.0);
}
