#version 330 core

out vec4 FragColor;

in vec2 TexCoords;
in vec4 FragPosLightSpace;
in vec3 FragPos;


uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedo;
uniform sampler2D ssao;
uniform sampler2D ssdoColor;//ssdo 间接光照
uniform sampler2D shadowMap;

struct Light {
  vec3 Position;
  vec3 Color;

  float Linear;
  float Quadratic;
};
uniform Light light;
uniform int enableSSAO;
uniform int enableSSDO;

float findBlocker(float currentDepth, vec3 projCoords,int samples){
    float blockerDepth=0.0;
    int blockerCount=0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    for(int x = -samples; x <= samples; ++x)
    {
        for(int y = -samples; y <= samples; ++y)
        {
            float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r; 
            if(pcfDepth < currentDepth){
                blockerDepth+=pcfDepth;
                blockerCount++;
            }        
        }    
    }
    if(blockerCount==0)
        return currentDepth;
    return blockerDepth/blockerCount;

}
float estimateLightWidth(float  receiverDistance,float avgBlockerDepth,float lightWidth, vec3 projCoords){
   //点光源
  //  float receiverDistance=projCoords.z;
    return (receiverDistance-avgBlockerDepth)/avgBlockerDepth*lightWidth;
}
float PCFandPcss(float currentDepth, float bias, vec3 projCoords,int samples){
    float shadow = 0.0;
    float avgBlockerDepth=findBlocker(currentDepth,projCoords,samples);
    if(avgBlockerDepth==-1.0)
        return 0.0;
    float filterRadius=estimateLightWidth(projCoords.z,avgBlockerDepth,0.5f,projCoords);
   
    int count=0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    filterRadius = max(1.0, min(filterRadius, 10.0)); // 限制模糊半径范围
    for(int x = -samples; x <= samples; ++x)
    {
        for(int y = -samples; y <= samples; ++y)
        {   

            float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x, y)*texelSize *filterRadius).r; 
            shadow += currentDepth - bias > pcfDepth  ? 1.0 : 0.0;        
            count++;
        }    
    }
    shadow /= count;
    return shadow;

}
float PCF(float currentDepth, float bias, vec3 projCoords,int samples){
    float shadow = 0.0;
   
    int count=0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    for(int x = -samples; x <= samples; ++x)
    {
        for(int y = -samples; y <= samples; ++y)
        {   

            float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r; 
            shadow += currentDepth - bias > pcfDepth  ? 1.0 : 0.0;        
            count++;
        }    
    }
    shadow /= count;
    return shadow;

}

float ShadowCalculation(vec4 fragPosLightSpace){
    //计算该点是否在阴影中
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;
    float closestDepth = texture(shadowMap, projCoords.xy).r;
    float currentDepth = projCoords.z;
    float bias=0.005;

    vec3 lightDir=normalize(light.Position-FragPos);
    vec3 normal=normalize(texture(gNormal, TexCoords).rgb);
    float shadow = 0.0;
    //shadow mapping
    shadow = currentDepth-bias > closestDepth  ? 1.0 : 0.0;
    //PCF
    //shadow= PCF(currentDepth,bias,projCoords,4);

    //PCSS
    //每个阴影处64+64次采样
    //shadow= PCFandPcss(currentDepth,bias,projCoords,8);

    // keep the shadow at 0.0 when outside the far_plane region of the light's frustum.
    if(projCoords.z > 1.0)
        shadow = 0.0;
        
    return shadow;
}


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

  //shadow
    float shadow = ShadowCalculation(FragPosLightSpace);
  diffuse *= attenuation;
  specular *= attenuation;
  lighting += (diffuse + specular);
  
  FragColor = vec4(lighting, 1.0);
    
}