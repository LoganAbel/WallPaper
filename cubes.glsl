#define R     iResolution
#define T     (iTime / 2.)
#define M     iMouse

#define PI    3.141592653
#define PI2   6.283185307

float hash21(vec2 a) { return fract(sin(dot(a, vec2(27.609, 57.583)))*43758.5453); }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

// Hexagon grid system, can be simplified but
// written out long-form for readability. 
// return vec2 uv and vec2 id
vec4 hexgrid(vec2 uv) {
    vec2 p1 = floor(uv/vec2(1.732,1))+.5;
    vec2 p2 = floor((uv-vec2(1,.5))/vec2(1.732,1))+.5;
    
    vec2 h1 = uv-p1*vec2(1.732,1);
    vec2 h2 = uv-(p2+.5)*vec2(1.732,1);
    return dot(h1,h1) < dot(h2,h2) ? vec4(h1,p1) : vec4(h2,p2+.5);
}

vec3 hsv( vec3 a ) {
    vec3 c = a + vec3(T*.1,0,0);
    vec3 rgb = clamp(abs(mod(c.x*2.+vec3(0,4,2),6.)-3.)-1.,0.,1.);
    return c.z * mix(vec3(1),rgb,c.y);
}

float truch(vec2 uv, vec2 id) {
    vec2 vv = uv;
    vec2 vd = floor(vv*10.);
    vv = fract(vv*10.)-.5;

    float rnd = hash21(vd+id);
    if(rnd>.5) vv.x = -vv.x;
    
    vec2 q = length(vv+.5)<length(vv-.5)? vv+.5:vv-.5;
    
    float d = abs(length(q)-.5)-.15;
    if(fract(rnd*43.57)>.77) d = min(length(vv.x)-.125,length(vv.y)-.125);
    
    return d;
}

void cube(inout vec3 C, vec2 uv, vec2 id, float px, float rnd, float lvl) {

    float ln = .025, hn = ln/2.;
    float rd = hash21(lvl+id*32.23);
    float hs = rd>.3?1.155:.65+.55*sin((rnd*PI2)+T*1.33);
    
    float d = max(abs(uv.x)*.866025 + abs(uv.y)/2., abs(uv.y))-(hs*.4);
    C = mix(C,vec3(1),smoothstep(px,-px,abs(d)-ln));
    
    uv.x -= (hs*.515);
    float tbase =length( abs(uv.x)*.866025 + abs(uv.y)/2.)- (hs*.45);
    
    float e = min(tbase, length(uv.y));
    
    rnd = fract(rnd*52.47);
    rnd += lvl*1.5;
    
    // color sides
    C = mix(C,hsv(vec3(rnd,.5,.8)),smoothstep(px,-px,max(tbase,d)) );
    C = mix(C,hsv(vec3(rnd+.15,1,.4)),smoothstep(px,-px,max(max(uv.y,-tbase),d)) );
    C = mix(C,hsv(vec3(rnd+.75,1,.2)),smoothstep(px,-px,max(max(max(-uv.y,uv.x),-tbase),d)) );

    if(lvl>1.&&fract(rd*52.47)>.36)C = mix(C,C*.25,smoothstep(px,-px,length(uv+vec2(.5,0)*hs)-(hs*.35)));
    
    // truchet patterns
    vec2 vv = vec2(uv.x*.866025,uv.y/2.);
    // math is kind of jank - wasnt sure how to properly do this so 
    // a lot of hunt and peck values
    id+=floor(rnd*15.);
    // top side
    vv.x += .51;
    vv *= rot(.78);
    float t = truch(vv*1.2,id);
    if(rd>.3) C = mix(C,clamp(C+.25,vec3(0),vec3(1)),smoothstep(px,-px,max(max(tbase,d),t)) );
    
    // left side
    vv = vec2(uv.x*.866025,uv.y/1.33)+vec2(uv.y*.5,0);
    vv.x += .65;
    t = truch(vv*vec2(.9,1.1),id);
    if(rd>.3)C = mix(C,clamp(C+.15,vec3(0),vec3(1)),smoothstep(px,-px,max(max(uv.y,max(d,-tbase)),t) ) );
    
    // right side
    vv = vec2(uv.x*.866025,uv.y/1.33)-vec2(uv.y*.5,0);
    vv.x += .65;
    t = truch(vv*vec2(.9,1.1),id);
    if(rd>.3)C = mix(clamp(C-.15,vec3(0),vec3(1)),C,smoothstep(px,-px,max(max(max(-uv.y,uv.x),-tbase),t)) );

    C = mix(C,vec3(1),smoothstep(px,-px,max(abs(e)-hn,d)));

}

const float scale = 5.;
const float mx = 3.;
const float mz = mx-1.;

void mainImage( out vec4 fragColor, in vec2 F )
{
    vec3 C = vec3(0);
    vec2 uv = (2.*F-R.xy)/max(R.x,R.y)*1.5;
    float px = fwidth(uv.x);
    
    uv *= scale;
    uv.y += T*.065;
    
    vec4 H;
    vec2 p, id;
    float rnd;
    
    // layer stack loop - smallest to large
    for(float i=0.;i<mx;i++) {
        float sc = mx-i;
        
        H = hexgrid(uv.yx*sc);
        p = H.xy, id = H.zw;
        rnd = hash21(id+i); 
        if(rnd>.25) cube(C,p,id,px,rnd,i+.5);
        if(i<mz) C *= (i+.5)*.25;
        uv.y += T*.125;
    }
    
    fragColor = vec4(pow(C,vec3(.4545)),1);
}