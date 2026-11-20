shader_type spatial;
varying vec3 pos;
void vertex(){pos=VERTEX;}
void fragment(){
	float d=-76.0-pos.z;
	float trail=-1.9+54.0*sin(d/83.0)+18.0*sin(d/27.0);
	float distance_to_path=abs(pos.x-trail);
	if(d>124.0 && d<218.0){distance_to_path=min(distance_to_path,abs(pos.x-trail-36.0*sin(3.14159*(d-124.0)/94.0)));}
	if(d>43.0 && d<104.0){
		float fork=trail-19.0*sin(PI*(d-43.0)/61.0);
		distance_to_path=min(distance_to_path,abs(pos.x-fork)+0.46);
	}
	float grain=sin(pos.x*5.1+sin(pos.z*2.1))*sin(pos.z*3.7);
	float path=(1.0-smoothstep(1.0,2.0,distance_to_path+grain*0.24))*(1.0-smoothstep(923.0,926.0,d));
	float band=sin(pos.z*0.031+cos(pos.x*0.12));
	vec3 soil=mix(vec3(0.21,0.19,0.11),vec3(0.31,0.28,0.18),band*0.5+0.5);
	vec3 ground=mix(soil,vec3(0.46,0.31,0.18),path);
	float creek_x=-1.9+54.0*sin(96.0/83.0)+18.0*sin(96.0/27.0);
	float creek_d=96.0+2.0*sin((pos.x-creek_x)/14.0);
	float creek=(1.0-smoothstep(1.3,4.8,abs(d-creek_d)))*(1.0-smoothstep(46.0,68.0,abs(pos.x-creek_x)));
	ground=mix(ground,vec3(0.33,0.29,0.24),creek);
	ALBEDO=mix(vec3(0.224,0.191,0.105),ground,smoothstep(0.0,14.0,d))*(0.95+0.05*grain);
	ROUGHNESS=1.0;
}
