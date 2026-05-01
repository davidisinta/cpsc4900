#version 410 core

in vec2 TexCoord;
uniform sampler2D uTexture;

out vec4 fragColor;

void main()
{
    vec2 tiledUV = TexCoord * 64.0;
    fragColor = texture(uTexture, tiledUV);
}
