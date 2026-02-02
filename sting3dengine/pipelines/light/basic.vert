#version 410 core

layout(location=0) in vec3 aPosition;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main()
{
	vec4 finalPosition = uProjection * uView * uModel * vec4(aPosition,1.0f);
	gl_Position = vec4(finalPosition.x, finalPosition.y, finalPosition.z, finalPosition.w);
}


