#version 410 core

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoord;
layout(location = 3) in ivec4 aBoneIds;
layout(location = 4) in vec4 aBoneWeights;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;
uniform mat4 uBones[170];

out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoord;

void main()
{
    int id0 = aBoneIds[0];
    int id1 = aBoneIds[1];
    int id2 = aBoneIds[2];
    int id3 = aBoneIds[3];

    mat4 skinMatrix = uBones[id0];

    vec4 skinnedPos = skinMatrix * vec4(aPosition, 1.0);
    vec3 skinnedNormal = mat3(skinMatrix) * aNormal;

    FragPos = vec3(uModel * skinnedPos);
    Normal = mat3(uModel) * skinnedNormal;
    TexCoord = aTexCoord;

    gl_Position = uProjection * uView * uModel * skinnedPos;
}
