#version 410 core

in vec2 vTexCoords;
in vec4 vWorldCoords;

out vec4 fragColor;

uniform sampler2D sampler1; //sand
uniform sampler2D sampler2; //grass
uniform sampler2D sampler3; //dirt
uniform sampler2D sampler4; //snow

uniform float gHeight0 = 50.0;
uniform float gHeight1 = 80.0;
uniform float gHeight2 = 140.0;
uniform float gHeight3 = 180.0;


vec4 GetColor(){	

	vec4 FinalColor;
	float height = vWorldCoords.y;


	if(height < gHeight0){
        FinalColor = texture(sampler1, vTexCoords);
    } else if (height < gHeight1){
		vec4 color0 = texture(sampler1, vTexCoords);
		vec4 color1 = texture(sampler2, vTexCoords);
		float Delta = gHeight1 - gHeight0;
		float factor = (height - gHeight0) / Delta;
		FinalColor = mix(color0, color1, factor);

    } else if (height < gHeight2){
		vec4 color0 = texture(sampler2, vTexCoords);
		vec4 color1 = texture(sampler3, vTexCoords);
		float Delta = gHeight2 - gHeight1;
		float factor = (height - gHeight1) / Delta;
		FinalColor = mix(color0, color1, factor);
    } else if(height < gHeight3){
		vec4 color0 = texture(sampler3, vTexCoords);
		vec4 color1 = texture(sampler4, vTexCoords);
		float Delta = gHeight3 - gHeight2;
		float factor = (height - gHeight2) / Delta;
		FinalColor = mix(color0, color1, factor);
    } else{
		FinalColor = texture(sampler4, vTexCoords);
	}
	return FinalColor;
}

void main(){
	fragColor = GetColor();
}
