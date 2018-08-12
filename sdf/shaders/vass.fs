#version 430 core

#define CODE_INVALID      0

#define CODE_INTERSECT    1
#define CODE_SUBSTRACT    2
#define CODE_UNIFY        3
#define CODE_REPEAT       4

#define CODE_DISK         5
#define CODE_RING         6
#define CODE_BOX          7
#define CODE_ROUNDED_BOX  8
#define CODE_RECT         9
#define CODE_ROUNDED_RECT 10
#define CODE_LINE         11
#define CODE_SEGMENT      12


#define ANTIALIASED true


#define CUTOFF 0.0


struct Command {
    uint  code;
    uint  _[3];
    float params[16];
};


uniform vec2 iResolution;
uniform uint iBufLen;

layout (std430, binding = 0) buffer buf_commands {
    Command commands[1024];
};

in vec2 fragCoord;

out vec4 fragColor;


float disk(vec2 p, float s) {
    return length(p)-s;
}

float box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}


vec4 blend(vec4 a, vec4 b) {
    return vec4(
        (b.r * b.a) + (a.r * (1.0 - b.a)),
        (b.g * b.a) + (a.g * (1.0 - b.a)),
        (b.b * b.a) + (a.b * (1.0 - b.a)),
        (b.a * b.a) + (a.a * (1.0 - b.a)) 
    );
}


void main() {
    vec2 pos = fragCoord*(iResolution*vec2(0.5));
    
    float dist0; // for the final blend against the background
    for (int i = 0; i < iBufLen; i += 1) {
        uint  code  = commands[i].code;
        float p[16] = commands[i].params;

        float dist = 0.0;
        vec4 color = vec4(p[0], p[1], p[2], p[3]);
            
        switch (code) {
        case CODE_DISK:
            dist = disk(pos-vec2(p[4], p[5]), p[6]*0.5);
            break;
        case CODE_BOX:
            dist = box(pos-vec2(p[4], p[5]), vec2(p[6]*0.5, p[7]*0.5));
            break;
        }

        if (i == 0) {
            // ignore the sdf for the first command, effectively handled when blending against background later
            fragColor.xyz = pow(color.xyz, vec3(2.2)); // need to transform from RGB to sRGB
            dist0 = dist;
        } else {
            float w = ANTIALIASED ? 1.5*fwidth(dist) : 0.0;
            float s = smoothstep(w/2.0, -w/2.0, dist);
            fragColor.xyz = pow(color.xyz, vec3(2.2))*s + fragColor.xyz*(1.0 - s); // need to transform from RGB to sRGB
            dist0 = min(dist0, dist);
        }
    }

    // blend against the background
    float w = ANTIALIASED ? 1.5*fwidth(dist0) : 0.0;
    fragColor.a = smoothstep(w/2.0, -w/2.0, dist0);
    fragColor.xyz = pow(fragColor.xyz, vec3(1.0/2.2)); // if the framebuffer is already sRGB, we don't need this final `pow`
}
