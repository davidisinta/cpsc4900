#version 410 core

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;

uniform vec3 uLightPos;
uniform vec3 viewpos;
uniform sampler2D uTexture;

out vec4 fragColor;

void main()
{
    vec3 lightColor = vec3(1.0, 1.0, 1.0);

    float ambientStrength = 0.3;
    vec3 ambient = ambientStrength * lightColor;

    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(uLightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    float specularStrength = 0.2;
    vec3 viewDir = normalize(viewpos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor;

    vec3 texColor = texture(uTexture, TexCoord).rgb;
    vec3 result = (ambient + diffuse + specular) * texColor;
    fragColor = vec4(result, 1.0);
}