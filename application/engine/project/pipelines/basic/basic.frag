#version 410 core

in vec3 Normal;
in vec3 FragPos;
in vec3 objectColor;

struct Light{
	float mColor[3];
	float mPosition[3];
	float mAmbientIntensity;
	float mSpecularIntensity;
	float mSpecularExponent;
} uLight;

uniform Light uLight1;
uniform vec3 viewpos;

out vec4 fragColor;

void main()
{

	vec3 lightPos = vec3(uLight1.mPosition[0],uLight1.mPosition[1],uLight1.mPosition[2]);
	vec3 lightColor = vec3(1.0, 1.0, 1.0);
	
	// ambient
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;
  	
    // diffuse 
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

	// specular
    float specularStrength = 0.5;
    vec3 viewDir = normalize(viewpos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);  
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor; 

	// Final color
    vec3 result = (ambient + diffuse + specular) * objectColor;
    fragColor = vec4(result, 1.0f);
}
