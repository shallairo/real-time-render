#version 330 core

out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedo;
uniform sampler2D ssao;
uniform sampler2D ssdoColor;//ssdo 间接光照

struct Light {
  vec3 Position;
  vec3 Color;

  float Linear;
  float Quadratic;
};
uniform Light light;
uniform int enableSSAO;
uniform int enableSSDO;
void main() {

  // 从 gbuffer 获取数据
  vec3 FragPos = texture(gPosition, TexCoords).rgb;
  vec3 Normal = texture(gNormal, TexCoords).rgb;
  vec3 Diffuse = texture(gAlbedo, TexCoords).rgb;
  float AmbientOcclusion = texture(ssao, TexCoords).r;

  if(enableSSAO == 0)
      AmbientOcclusion = 1.0;
  
// SSDO 间接光照颜色
    vec3 indirectLight = vec3(0.0);
    if (enableSSDO == 1)
        indirectLight = texture(ssdoColor, TexCoords).rgb;

  // 计算光照
  vec3 ambient = vec3(0.3 * Diffuse * AmbientOcclusion);
  vec3 lighting = ambient+indirectLight; // 环境光+间接光照
  vec3 viewDir = normalize(-FragPos); // viewpos (0, 0, 0)

  // diffuse
  vec3 lightDir = normalize(light.Position - FragPos);
  vec3 diffuse = max(dot(Normal, lightDir), 0.0) * Diffuse * light.Color;

  // specular
  vec3 halfwayDir = normalize(lightDir + viewDir);
  float spec = pow(max(dot(Normal, halfwayDir), 0.0), 64.0);
  vec3 specular = light.Color * spec;

  // attenuation
  float distance = length(light.Position - FragPos);
  float attenuation = 1.0 / (1.0 + light.Linear * distance + light.Quadratic * distance * distance);


  diffuse *= attenuation;
  specular *= attenuation;
  lighting += diffuse + specular;

  FragColor = vec4(lighting, 1.0);

}