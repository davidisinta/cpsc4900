#version 410 core
in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;
uniform vec3 uLightPos;
uniform vec3 viewpos;
uniform sampler2D uTexture;
uniform vec3 uFogColor;
uniform float uFogStart;
uniform float uFogEnd;
out vec4 fragColor;
void main()
{
    vec3 lightColor = vec3(1.0, 1.0, 1.0);
    float ambientStrength = 0.65;
    vec3 ambient = ambientStrength * lightColor;
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(uLightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = 0.45 * diff * lightColor;
    float specularStrength = 0.1;
    vec3 viewDir = normalize(viewpos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 16.0);
    vec3 specular = specularStrength * spec * lightColor;
    vec3 texColor = texture(uTexture, TexCoord).rgb;
    vec3 result = (ambient + diffuse + specular) * texColor;
    float dist = distance(viewpos, FragPos);
    float fogFactor = clamp((uFogEnd - dist) / (uFogEnd - uFogStart), 0.0, 1.0);
    vec3 finalColor = mix(uFogColor, result, fogFactor);
    fragColor = vec4(finalColor, 1.0);
}
