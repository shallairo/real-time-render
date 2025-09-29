#version 330 core
out vec4 FragColor;

in VS_OUT {
    vec3 FragPos;
    vec3 Normal;
    vec2 TexCoords;
    vec4 FragPosLightSpace;
} fs_in;

uniform sampler2D diffuseTexture;
uniform sampler2D shadowMap;

uniform vec3 lightPos;
uniform vec3 viewPos;
// float PCF(float currentDepth, float bias, vec2 projCoords){
//     float shadow = 0.0;
//     vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
//     for(int x = -1; x <= 1; ++x)
//     {
//         for(int y = -1; y <= 1; ++y)
//         {
//             float pcfDepth = texture(shadowMap, projCoords + vec2(x, y) * texelSize).r; 
//             shadow += currentDepth - bias > pcfDepth  ? 1.0 : 0.0;        
//         }    
//     }
//     shadow /= 9.0;
//     return shadow;

// }
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

    vec3 lightDir=normalize(lightPos-fs_in.FragPos);
    vec3 normal=normalize(fs_in.Normal);
    float shadow = 0.0;
    //shadow mapping
    //shadow = currentDepth-bias > closestDepth  ? 1.0 : 0.0;
    //PCF
    //shadow= PCF(currentDepth,bias,projCoords,4);
    //PCSS
    //每个阴影处64+64次采样
    shadow= PCFandPcss(currentDepth,bias,projCoords,8);
    // keep the shadow at 0.0 when outside the far_plane region of the light's frustum.
    if(projCoords.z > 1.0)
        shadow = 0.0;
        
    return shadow;
}
void main()
{           
    vec3 color = texture(diffuseTexture, fs_in.TexCoords).rgb;
    vec3 normal = normalize(fs_in.Normal);
    vec3 lightColor = vec3(1.0);
    // ambient
    vec3 ambient = 0.15 * color;
    // diffuse
    vec3 lightDir = normalize(lightPos - fs_in.FragPos);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * lightColor;
    // specular
    vec3 viewDir = normalize(viewPos - fs_in.FragPos);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = 0.0;
    vec3 halfwayDir = normalize(lightDir + viewDir);  
    spec = pow(max(dot(normal, halfwayDir), 0.0), 64.0);
    vec3 specular = spec * lightColor;    
    // calculate shadow
    float shadow = ShadowCalculation(fs_in.FragPosLightSpace);                      
    vec3 lighting = (ambient + (1.0 - shadow) * (diffuse + specular)) * color;    
    
    FragColor = vec4(lighting, 1.0);
}