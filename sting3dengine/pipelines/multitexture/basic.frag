#version 410 core

in vec2 vTexCoords;
in vec4 vWorldCoords;

out vec4 fragColor;

uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D sampler3;
uniform sampler2D sampler4;

vec3 GetColor(){
		vec3 color = vec3(1.0,1.0,1.0);

		color+=texture(sampler1,vTexCoords).rgb*0.25;
		color+=texture(sampler2,vTexCoords).rgb*0.25;
		color+=texture(sampler3,vTexCoords).rgb*0.25;
		color+=texture(sampler4,vTexCoords).rgb*0.25;
		
		return color;
}

void main(){

		fragColor = vec4(GetColor(), 1.0);
}
