shader_type sky;

uniform float dusk : hint_range(0.0, 1.0) = 0.0;
uniform float nightfall : hint_range(0.0, 1.0) = 0.0;
uniform vec4 high_day : source_color = vec4(0.38,0.57,0.71,1.0);
uniform vec4 rim_day : source_color = vec4(0.95,0.77,0.62,1.0);
uniform vec4 high_night : source_color = vec4(0.045,0.067,0.14,1.0);
uniform vec4 rim_night : source_color = vec4(0.29,0.31,0.43,1.0);

uniform sampler2D faint_stars : filter_linear_mipmap, repeat_enable;
float star_field(vec3 dir){
	vec2 uv=vec2(atan(dir.x,dir.z)/TAU+0.5,acos(clamp(dir.y,-1.0,1.0))/PI);
	// Explicit gradients avoid a mip level discontinuity across the azimuth seam.
	vec2 dx=dFdx(uv), dy=dFdy(uv);
	dx.x-=round(dx.x); dy.x-=round(dy.x);
	return textureGrad(faint_stars,uv,dx,dy).r;
}

uniform vec4 catalog[20];
uniform vec3 moon_dir;
uniform vec3 sun_dir;
uniform float other_world = 0.0;
uniform float cloud_cover = 0.0;

// Project the solar direction onto the visible lunar hemisphere for the terminator.
vec3 disc(vec3 sight, vec3 center, vec3 light, float radius, vec3 tint, vec3 backdrop) {
	vec3 offset = (sight-center)/radius;
	float r = length(offset);
	if (r>1.15) return backdrop;
	vec3 normal = normalize(offset-center*sqrt(max(0.0,1.0-r*r)));
	float lit = smoothstep(-0.025,0.06,dot(normal,light));
	float maria = 0.84+0.16*sin(offset.x*10.0+sin(offset.y*7.0))*cos(offset.y*9.0);
	return mix(backdrop,tint*(0.065+lit*maria),1.0-smoothstep(0.85,1.15,r));
}

void sky(){
	float height = max(EYEDIR.y,0.0);
	float blend = smoothstep(0.0,0.79,height);
	vec3 horizon = mix(rim_day.rgb,vec3(0.92,0.43,0.24),dusk);
	vec3 daytime = mix(horizon,high_day.rgb,blend);
	vec3 dark = mix(rim_night.rgb,high_night.rgb,smoothstep(0.0,0.48,height));
	float points = star_field(EYEDIR);
	vec3 earth = dark;
	for (int i=0; i<20; i++){
		float power = clamp(1.4-0.22*catalog[i].w,0.65,1.8);
		points += power*(1.0-smoothstep(0.0,0.0042*power,length(EYEDIR-catalog[i].xyz)));
	}
	earth += vec3(0.90,0.93,1.0)*points;
	earth = disc(EYEDIR,moon_dir,sun_dir,0.019,vec3(1.0,0.95,0.84),earth);
	vec3 alien = mix(vec3(0.19,0.095,0.18),vec3(0.024,0.013,0.07),blend);
	alien += vec3(0.66,0.86,0.95)*(star_field(EYEDIR.zxy));
	alien=disc(EYEDIR,normalize(vec3(0.35,0.48,-1.0)),normalize(vec3(-1.0,0.6,0.4)),0.038,vec3(0.95,0.72,0.51),alien);
	alien=disc(EYEDIR,normalize(vec3(0.08,0.66,-1.0)),normalize(vec3(-1.0,0.6,0.4)),0.016,vec3(0.65,0.83,0.91),alien);
	vec2 haze = EYEDIR.xz * 5.0 / max(0.52, height + 0.44);
	float layered = sin(haze.x + sin(haze.y * 1.1)) * 0.29 + cos(haze.y * 1.9 - haze.x * 0.5) * 0.15;
	float clouds = smoothstep(0.1, 0.67, layered + cloud_cover) * smoothstep(0.0, 0.15, height);
	daytime = mix(daytime, mix(vec3(0.43, 0.47, 0.48), vec3(0.58, 0.59, 0.58), clouds), clouds * 0.86);
	earth = mix(earth, dark * 0.88, clouds * 0.68);
	COLOR=mix(daytime,mix(dark,mix(earth,alien,other_world),smoothstep(0.0,0.065,height)),nightfall);
}
