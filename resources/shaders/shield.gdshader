// Recreation of Daruks Protection from BotW
// Made by NekotoArts
//
//
//
// Garbaj best waifu
//
// This was written in VisualShader
// thats why the variables are called "n_out24p0" and stuff

shader_type spatial;
render_mode specular_schlick_ggx, unshaded;

uniform float fresnel_blend;
uniform float fresnel_size;
uniform float fresnel_power;
uniform vec4 fresnel_color_top: source_color;
uniform float brightness;
uniform float time_scale;
uniform float tile;
uniform sampler2D symbol_texture;
uniform float symbol_blend;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// FractalSimplexNoise2D

vec3 _permute_simplex2_n0ise_fractal(vec3 x) {
	return ((x*34.0)+1.0)*x-floor(((x*34.0)+1.0)*x*(1.0/289.0))*289.0;
}

float simplex2dN0iseFractalFunc(vec2 v) {
	vec4 C = vec4(0.211324865405187,
				0.366025403784439,
				-0.577350269189626,
				0.024390243902439);
	
	vec2 i  = floor(v + dot(v, C.yy) );
	vec2 x0 = v -   i + dot(i, C.xx);
	
	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = vec4(x0.xy, x0.xy) + C.xxzz;
	x12.xy -= i1;
	
	i = i - floor(i * (1.0 / 289.0)) * 289.0;
	vec3 p = _permute_simplex2_n0ise_fractal(_permute_simplex2_n0ise_fractal(i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0));
	
	vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), vec3(0.0));
	m = m * m;
	m = m * m;
	
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	
	m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
	
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}
float simplexNoise2DFBM(vec2 _uv_sn2fbm, int _oct_sn2fbm, vec2 _per_sn2fbm, float _lac_sn2fbm,
						float _persist_sn2fbm, float _rot_sn2fbm, float _ampl_sn2fbm, vec2 _shift_sn2fbm) {
	float _v = 0.0;
	float _a = _ampl_sn2fbm;
	mat2 _r0t = mat2(vec2(cos(_rot_sn2fbm), sin(_rot_sn2fbm)), vec2(-sin(_rot_sn2fbm), cos(_rot_sn2fbm)));
	for (int i = 0; i < _oct_sn2fbm; ++i) {
		_v += _a * simplex2dN0iseFractalFunc(_uv_sn2fbm * _per_sn2fbm);
		_uv_sn2fbm = _r0t * _uv_sn2fbm * _lac_sn2fbm + _shift_sn2fbm;
		_a *= _persist_sn2fbm;
	}
	return (min(_v, 1.0) + 1.0) * 0.5;
}

// FractalWorleyNoise2D

vec2 cellular2dNoiseFractalFunc(vec2 P, float _jitter_w2d) {
	float K = 0.142857142857; // 1/7
	float Ko = 0.428571428571; // 3/7
	
	vec2 Pi = floor(P) - floor(floor(P) * (1.0 / 289.0)) * 289.0;
	vec2 Pf = fract(P);
	vec3 oi = vec3(-1.0, 0.0, 1.0);
	vec3 of = vec3(-0.5, 0.5, 1.5);
	vec3 px = (34.0*(Pi.x+oi)+1.0)*(Pi.x+oi)-floor((34.0*(Pi.x+oi)+1.0)*(Pi.x+oi)*(1.0/289.0))* 289.0;
	vec3 p = (34.0*(px.x+Pi.y+ oi)+1.0)*(px.x+Pi.y+ oi)-floor((34.0*(px.x+Pi.y+oi)+1.0)*(px.x+Pi.y+ oi)*(1.0/289.0))*289.0;
	vec3 ox = fract(p*K) - Ko;
	vec3 oy = (floor(p*K) - floor(floor(p*K) * (1.0 / 7.0)) * 7.0) * K - Ko;
	vec3 dx = Pf.x + 0.5 + _jitter_w2d*ox;
	vec3 dy = Pf.y - of + _jitter_w2d*oy;
	vec3 d1 = dx * dx + dy * dy;
	p = (34.0*(px.y+Pi.y+oi)+1.0)*(px.y+Pi.y+oi)-floor((34.0*(px.y+Pi.y+oi)+1.0)*(px.y+Pi.y+oi)*(1.0/289.0))*289.0;
	ox = fract(p*K) - Ko;
	oy = (floor(p*K) - floor(floor(p*K) * (1.0 / 7.0)) * 7.0) * K - Ko;
	dx = Pf.x - 0.5 + _jitter_w2d*ox;
	dy = Pf.y - of + _jitter_w2d*oy;
	vec3 d2 = dx * dx + dy * dy;
	p = (34.0*(px.z+Pi.y+oi)+1.0)*(px.z+Pi.y+oi)-floor((34.0*(px.z+Pi.y+oi)+1.0)*(px.z+Pi.y+oi)*(1.0/289.0))*289.0;
	ox = fract(p*K) - Ko;
	oy = (floor(p*K) - floor(floor(p*K) * (1.0 / 7.0)) * 7.0) * K - Ko;
	dx = Pf.x - 1.5 + _jitter_w2d*ox;
	dy = Pf.y - of + _jitter_w2d*oy;
	vec3 d3 = dx * dx + dy * dy;
	vec3 d1a = min(d1, d2);
	d2 = max(d1, d2);
	d2 = min(d2, d3);
	d1 = min(d1a, d2);
	d2 = max(d1a, d2);
	d1.xy = (d1.x < d1.y) ? d1.xy : d1.yx;
	d1.xz = (d1.x < d1.z) ? d1.xz : d1.zx;
	d1.yz = min(d1.yz, d2.yz);
	d1.y = min(d1.y, d1.z);
	d1.y = min(d1.y, d2.x);
	return sqrt(d1.xy);
}
float cellularNoise2DFBM(vec2 _uv_cnfbm, int _oct_cnfbm, vec2 _per_cnfbm, float _lac_cnfbm, float _persist_cnfbm,
		float _rot_cnfbm, float _ampl_cnfbm, vec2 _shift_cnfbm, float _jitter_cnfbm, bool _use_F2_cnfbm) {
	float _v = 0.0;
	float _a = _ampl_cnfbm;
	mat2 _r0t = mat2(vec2(cos(_rot_cnfbm), sin(_rot_cnfbm)), vec2(-sin(_rot_cnfbm), cos(_rot_cnfbm)));
	for (int i = 0; i < _oct_cnfbm; ++i) {
		vec2 _cell_noiseF12 = cellular2dNoiseFractalFunc(_uv_cnfbm * _per_cnfbm, _jitter_cnfbm);
		if (_use_F2_cnfbm) {
			_v += _a * _cell_noiseF12.y;
		} else {
			_v += _a * _cell_noiseF12.x;
		}
		_uv_cnfbm = _r0t * _uv_cnfbm * _lac_cnfbm + _shift_cnfbm;
		_a *= _persist_cnfbm;
	}
	return _v;
}

// TileUV

vec2 t1leMapUV(vec2 _uv_t1le_t1mp, float _w1dth_t1mp, float _he1ght_t1mp, float _t1le_nmbr_t1mp){
	_t1le_nmbr_t1mp = min(max(floor(_t1le_nmbr_t1mp), 0.0), _w1dth_t1mp * _he1ght_t1mp - 1.0);
	vec2 tcrcp = vec2(1.0) / vec2(_w1dth_t1mp, _he1ght_t1mp);
	float ty =floor(_t1le_nmbr_t1mp * tcrcp.x);
	float tx = _t1le_nmbr_t1mp - _w1dth_t1mp * ty;
	return (_uv_t1le_t1mp + vec2(tx, ty)) * tcrcp;
}


void vertex() {
// Output:0

}

void fragment() {
// ScalarUniform:25
	float n_out25p0 = fresnel_blend;

// ScalarUniform:27
	float n_out27p0 = fresnel_size;

// ScalarOp:26
	float n_out26p0 = n_out25p0 + n_out27p0;

// ScalarUniform:3
	float n_out3p0 = fresnel_power;

// Fresnel:2
	float n_out2p0 = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), n_out3p0);

// ScalarSmoothStep:24
	float n_out24p0 = smoothstep(n_out25p0, n_out26p0, n_out2p0);

// ColorUniform:9
	vec3 n_out9p0 = fresnel_color_top.rgb;
	float n_out9p1 = fresnel_color_top.a;

// ScalarUniform:43
	float n_out43p0 = brightness;

// VectorOp:42
	vec3 n_out42p0 = n_out9p0 * vec3(n_out43p0);

// VectorOp:8
	vec3 n_out8p0 = vec3(n_out24p0) * n_out42p0;

// Input:17
	vec3 n_out17p0 = vec3(UV, 0.0);

// ScalarUniform:19
	float n_out19p0 = time_scale;

// ScaledTIME:18
	float n_out18p0;
	{
		n_out18p0 = n_out19p0 * TIME;
	}

// VectorOp:16
	vec3 n_out16p0 = n_out17p0 + vec3(n_out18p0);

// FractalSimplexNoise2D:23
	float n_in23p1 = 3.00000;
	vec3 n_in23p2 = vec3(2.00000, 2.00000, 0.00000);
	float n_in23p3 = 2.00000;
	float n_in23p4 = 0.80000;
	float n_in23p5 = 0.50000;
	float n_in23p6 = 0.50000;
	vec3 n_in23p7 = vec3(0.50000, 0.50000, 0.00000);
	float n_out23p0;
	{
		n_out23p0 = simplexNoise2DFBM(n_out16p0.xy, int(n_in23p1), n_in23p2.xy, n_in23p3, n_in23p4, n_in23p5, n_in23p6, n_in23p7.xy);
	}

// ScalarOp:14
	float n_in14p1 = 1.00000;
	float n_out14p0 = n_out23p0 + n_in14p1;

// VectorOp:12
	vec3 n_out12p0 = n_out8p0 * vec3(n_out14p0);

// FractalWorleyNoise2D:22
	float n_in22p1 = 5.00000;
	vec3 n_in22p2 = vec3(2.00000, 2.00000, 0.00000);
	float n_in22p3 = 2.00000;
	float n_in22p4 = 0.80000;
	float n_in22p5 = 0.50000;
	float n_in22p6 = 0.30000;
	vec3 n_in22p7 = vec3(0.50000, 0.50000, 0.00000);
	float n_in22p8 = 1.00000;
	bool n_in22p9 = false;
	float n_out22p0;
	{
		n_out22p0 = cellularNoise2DFBM(n_out16p0.xy, int(n_in22p1), n_in22p2.xy, n_in22p3, n_in22p4, n_in22p5, n_in22p6, n_in22p7.xy, n_in22p8, n_in22p9);
	}

// VectorOp:21
	vec3 n_out21p0 = n_out12p0 * vec3(n_out22p0);

// ScalarUniform:34
	float n_out34p0 = tile;

// TileUV:33
	float n_in33p3 = 0.00000;
	vec3 n_out33p0;
	{
		n_out33p0.xy = t1leMapUV(n_out16p0.xy, n_out34p0, n_out34p0, n_in33p3);
	}

// TextureUniform:29
	vec3 n_out29p0;
	float n_out29p1;
	{
		vec4 n_tex_read = texture(symbol_texture, n_out33p0.xy);
		n_out29p0 = n_tex_read.rgb;
		n_out29p1 = n_tex_read.a;
	}

// ColorFunc:40
	vec3 n_out40p0;
	{
		vec3 c = n_out29p0;
		float max1 = max(c.r, c.g);
		float max2 = max(max1, c.b);
		float max3 = max(max1, max2);
		n_out40p0 = vec3(max3, max3, max3);
	}

// VectorFunc:41
	vec3 n_out41p0 = vec3(1.0, 1.0, 1.0) - n_out40p0;

// ScalarUniform:39
	float n_out39p0 = symbol_blend;

// VectorOp:36
	vec3 n_out36p0 = n_out41p0 + vec3(n_out39p0);

// VectorOp:31
	vec3 n_out31p0 = n_out9p0 * n_out36p0;

// VectorFunc:38
	vec3 n_out38p0 = max(min(n_out31p0, vec3(1.0)), vec3(0.0));

// VectorOp:28
	vec3 n_out28p0 = n_out21p0 * n_out38p0;

// Input:7
	vec3 n_out7p0 = vec3(SCREEN_UV, 0.0);

// Input:5

// Texture:6
	vec3 n_out6p0;
	float n_out6p1;
	{
		vec4 SCREEN_TEXTURE_tex_read = texture(SCREEN_TEXTURE, n_out7p0.xy);
		n_out6p0 = SCREEN_TEXTURE_tex_read.rgb;
		n_out6p1 = SCREEN_TEXTURE_tex_read.a;
	}

// VectorOp:4
	vec3 n_out4p0 = n_out28p0 + n_out6p0;

// Output:0
	ALBEDO = n_out4p0;

}

void light() {
// Output:0

}
