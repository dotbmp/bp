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


#define OPERATION_INVALID 0

#define OPERATION_DRAW    1
#define OPERATION_QUEUE   2


#define ANTIALIASED true


#define DIST_MIN -1.0f
#define DIST_MAX  1.0f


struct Command {
    uint  operation;
    uint  code;
    uint  id0;
    uint  id1;
    float params[16];
};


uniform vec2 iResolution;
uniform uint iBufLen;

layout (std430, binding = 0) buffer buf_commands {
    Command commands[1024];
};

in vec2 fragCoord;

out vec4 fragColor;



float dists[1024];



float intersect(float d1, float d2) {
    return max(d1, d2);
}
float substract(float d1, float d2) {
    return max(-d1, d2);
}

float unify(float d1, float d2) {
    return min(d1, d2);
}


float disk(vec2 p, float s) {
    return length(p)-s;
}

float box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float ubox(vec2 p, vec2 b) {
    return length(max(abs(p)-b, 0.0));
}

float rbox(vec2 p, vec2 b, float r) {
    return length(max(abs(p)-(b-r), 0.0))-r;
}

float sd_triangle(vec2 p, vec2 p1, vec2 p2, vec2 p3) {
    float d1 = dot(normalize(vec2((p2.y - p1.y), -(p2.x - p1.x))), p - p1);
    float d2 = dot(normalize(vec2((p3.y - p2.y), -(p3.x - p2.x))), p - p2);
    float d3 = dot(normalize(vec2((p1.y - p3.y), -(p1.x - p3.x))), p - p3);
    
    return max(d1, max(d2, d3));
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
    fragColor = vec4(0, 0, 0, 0);

    vec2 pos = fragCoord*(iResolution*vec2(0.5));
    
    for (int i = 0; i < iBufLen; i += 1) {
        uint  code  = commands[i].code;
        float p[16] = commands[i].params;

        vec4 color = vec4(p[0], p[1], p[2], p[3]);
            
        switch (code) {
        case CODE_INTERSECT:
            dists[i] = intersect(dists[commands[i].id0], dists[commands[i].id1]);
            break;

        case CODE_SUBSTRACT:
            dists[i] = substract(dists[commands[i].id0], dists[commands[i].id1]);
            break;

        case CODE_UNIFY:
            dists[i] = unify(dists[commands[i].id0], dists[commands[i].id1]);
            break;

        case CODE_REPEAT:

        case CODE_DISK:
            dists[i] = disk(pos-vec2(p[4], p[5]), p[6]*0.5);
            break;
        
        case CODE_RING: {
            float dist0 = disk(pos-vec2(p[4], p[5]), (p[6]-p[7])*0.5);
            float dist1 = disk(pos-vec2(p[4], p[5]), (p[6]+p[7])*0.5);
            dists[i] = substract(dist0, dist1);
            break;
        }
        
        case CODE_BOX: {
            vec2 loc = vec2(p[4], p[5]);
            vec2 dim = vec2(p[6], p[7]) * vec2(0.5);

            dists[i] = box(pos-loc, dim);
            
            break;
        }

        case CODE_RECT: {
            float dist0 = box(pos-vec2(p[4], p[5]), vec2((p[6]-p[8])*0.5, (p[7]-p[8])*0.5));
            float dist1 = box(pos-vec2(p[4], p[5]), vec2((p[6]+p[8])*0.5, (p[7]+p[8])*0.5));
            dists[i] = substract(dist0, dist1);
            break;
        }

        case CODE_ROUNDED_BOX:
            vec2  loc    = vec2(p[4], p[5]);
            vec2  dim    = vec2(p[6], p[7]) * vec2(0.5);
            float radius = p[8];

            dists[i] = rbox(pos-loc, dim, radius);
            
            break; 

        case CODE_ROUNDED_RECT: {
            float dist0 = rbox(pos-vec2(p[4], p[5]), vec2((p[6]-p[9])*0.5, (p[7]-p[9])*0.5), p[8]);
            float dist1 = rbox(pos-vec2(p[4], p[5]), vec2((p[6]+p[9])*0.5, (p[7]+p[9])*0.5), p[8]);
            dists[i] = substract(dist0, dist1);
            break;
        }

        case CODE_LINE: break;

        case CODE_SEGMENT: break;
        }


        if (commands[i].operation == OPERATION_DRAW) {
            if (true) {
                if (ANTIALIASED) {
                    color.a *= smoothstep(DIST_MIN, DIST_MAX, 0.5 - dists[i]);
                }
                else {
                    color.a *= dists[i] < 0 ? 1 : 0;
                }
            }
            else {
                color.a *= dists[i]*0.01 ;
            }

    
            fragColor = blend(fragColor, color);
        }
    
    }
}
