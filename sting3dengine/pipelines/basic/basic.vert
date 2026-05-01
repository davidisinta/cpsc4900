#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;

out vec3 FragPos;
out vec3 Normal;
out vec3 objectColor;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main()
{

	objectColor = aNormal;
	FragPos = vec3(uModel * vec4(aPosition, 1.0));
    Normal = mat3(transpose(inverse(uModel))) * aNormal; 
	vec4 finalPosition = uProjection * uView * uModel * vec4(aPosition,1.0f);

	gl_Position = vec4(finalPosition.x, finalPosition.y, finalPosition.z, finalPosition.w);
}
