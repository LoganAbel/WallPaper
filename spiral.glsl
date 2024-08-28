
float smin(float a, float b) {
	float k = 7.;
	float res = exp(-k*a) + exp(-k*b);
	return -log(res) / k;
}

float sdHexPrism(vec3 p, vec2 h) {
	vec3 q = abs(p);
	return max(q.z - h.y, max((q.x*0.866025 + q.y*0.5), q.y) - h.x);
}

float sc(vec3 p, float r) {
	float s1 = sdHexPrism(p, vec2(r, 1e6));
	float s2 = sdHexPrism(p.yzx, vec2(r, 1e6));
	float s3 = sdHexPrism(p.zxy, vec2(r, 1e6));
	return min(s1, min(s2, s3));
}

float ssc(vec3 p, float r) {
	float s1 = sdHexPrism(p, vec2(r, 1e6));
	float s2 = sdHexPrism(p.yzx, vec2(r, 1e6));
	float s3 = sdHexPrism(p.zxy, vec2(r, 1e6));
	return smin(s1, smin(s2, s3));
}

mat2 r2d(float a) {
	float c = cos(a), s = sin(a);
	return mat2(c, s, -s, c);
}

float m_particule(vec3 p, float r, float x, float d, vec2 s) {
	float t = iTime*.3;
	p.z = mod(p.z + d, 4.) - 2.;
	p.x += s.x*sin(t)*.6;
	p.y += s.y*cos(t*2.)*.5;
	p.z += sin(t*2.);//*2.6;

					 //p.xz *= r2d(iTime);
					 //p.xy *= r2d(iTime);
					 //return length(max(abs(p) - vec3(r*.5), 0.));// - r;
					 //return sdHexPrism(p, vec2(r, r*.5));
	return length(p) - r;
}

vec2 de(vec3 p) {
	float d = 0., s = 1.;

	float mp1 = m_particule(p, .02, .5, 0., vec2(-1.));
	float mp2 = m_particule(p, .045, -.7, 3., vec2(-1., 1.));
	float mp3 = m_particule(p, .03, .1, 2., vec2(1., -1.));
	float mp4 = m_particule(p, .025, .1, 1., vec2(1., 1.));

	float particules = min(mp1, min(mp2, mp3));
	particules = min(particules, mp4);

	p.xy *= r2d(iTime*.1 + p.z);

	vec3 q = p;

	for (int i = 0; i < 5; i++) {
		q = mod(p*s + 1., 2.) - 1.;
		d = max(d, -ssc(q, .59) / s);
		s += 6.;
	}

	if (d < particules)
		return vec2(d, 1);
	else
		return vec2(particules, 2);
}

/*
vec3 normal(in vec3 pos)
{
	vec2 e = vec2(1., -1.)*.5773*.0005;
	return normalize(e.xyy*de(pos + e.xyy).x +
		e.yyx*de(pos + e.yyx).x +
		e.yxy*de(pos + e.yxy).x +
		e.xxx*de(pos + e.xxx).x);
}
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy - .5;
	uv.x *= iResolution.x / iResolution.y;

	vec3 ro = vec3(.15*cos(iTime), .1*sin(iTime), -iTime*.4), p;
	vec3 rd = normalize(vec3(uv, -1));
	p = ro;

	float it = 0.;
	vec2 res;
	for (float i = 0.; i < 1.; i += .02) {
		it = i;
		res = de(p);
		if (res.x < .001) break;
		p += rd*res.x*.75;
	}

	vec3 c;

	if (res.y == 2.) {
		c = mix(vec3(1., .1, .5), vec3(.2, .1, .2), it);
		//c += vec3(.5, .2, .4) * max(0., dot(-rd, normal(p)));
	}
	else {
		c = mix(vec3(.2, .7, .7), vec3(.2, .1, .2), it);
	}

	float dist = length(ro - p);
	c = mix(c, vec3(.2, .1, .2), 1. - exp(-.1 * dist*dist));

	fragColor = vec4(c, 1.0);
}