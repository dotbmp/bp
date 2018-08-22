#version 430 core

in  vec4 fragCoord;
out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iCursor;
uniform bool iClickLeft;
uniform bool iClickRight;


#define CI vec3(.3,.5,.6)
#define CO vec3(.2)
#define CM vec3(.0)
#define CE vec3(.8,.7,.5)

#define PI  3.14159265358979323846264338327950288
#define TAU 6.28318530717958647692528676655900576


vec2 N22(vec2 p) {
    vec3 a = fract(p.xyx*vec3(123.34, 234.34, 345.65));
    a += dot(a, a+34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
}

vec4 blend(vec4 a, vec4 b) {
    return vec4(
        (b.r * b.a) + (a.r * (1.0 - b.a)),
        (b.g * b.a) + (a.g * (1.0 - b.a)),
        (b.b * b.a) + (a.b * (1.0 - b.a)),
        (b.a * b.a) + (a.a * (1.0 - b.a)) 
    );
}

float sd_line(vec2 p, vec2 a, vec2 b, float r) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa-ba*h) - r;
}



float intersect(float d1, float d2) {
    return max(d1, d2);
}
float substract(float d1, float d2) {
    return max(-d1, d2);
}

float unify(float d1, float d2) {
    return min(d1, d2);
}


vec2 polar(vec2 p) {
    return vec2(atan(p.x, p.y), length(p));
}


vec2 mobius(vec2 p, vec2 z1, vec2 z2){
    z1 = p - z1; p -= z2;
    return vec2(dot(z1, p), z1.y*p.x - z1.x*p.y)/dot(p, p);
}



float box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float metaball(vec2 p, float r)
{
    return r / dot(p, p);
}

vec3 samplef(in vec2 uv)
{
    float t0 = sin(iTime * 1.9) * .46;
    float t1 = sin(iTime * 2.4) * .49;
    float t2 = cos(iTime * 1.4) * .57;

    float r = metaball(uv + vec2(t0, t2), .33) *
              metaball(uv - vec2(t0, t1), .27) *
              metaball(uv + vec2(t1, t2), .59);

    vec3 c = (r > .4 && r < .7)
              ? (vec3(step(.1, r*r*r)) * CE)
              : (r < .9 ? (r < .7 ? CO: CM) : CI);

    return c;
}

void main() {
    fragColor = vec4(0);

    vec2 uv = (fragCoord.xy*0.5*iResolution.xy);
    vec2 pos = fragCoord.xy*iResolution.xy*0.5;

    vec4 pink   = vec4(1.0, 0.5, 1.0, 1.0);
    vec4 yellow = vec4(1.0, 1.0, 0.0, 1.0);

    vec2 n = N22(uv);
    n = polar(n);

    vec4 col0 = vec4(pink.rgb,   smoothstep(-1, 1, 0.5-n.x));
    vec4 col1 = vec4(yellow.rgb, smoothstep(-1, 1, 0.5-n.y));
    fragColor = blend(col0, col1);
}
