#version 410 core

in  vec2 vTexCoords;
out vec4 fragColor;

uniform sampler2D sampler1;

void main()
{
	fragColor = vec4(texture(sampler1,vTexCoords).rgb, 1.0);
}
