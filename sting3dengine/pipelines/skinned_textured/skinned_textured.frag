#version 410 core
in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;
uniform sampler2D uTexture;
uniform vec3 uLightPos;
out vec4 fragColor;
void main()
{
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
}
