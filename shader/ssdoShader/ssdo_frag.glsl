
#version 330 core
out vec3 FragColor;
in vec2 TexCoords;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedo;
uniform sampler2D texNoise;

uniform vec3 samples[64];
uniform mat4 projection;

const float radius =0.5f;
const int kernelSize = 64;
float bias = 0.0025;
// 根据屏幕尺寸除以噪声大小在屏幕上平铺纹理
const vec2 noiseScale = vec2(2560.0 / 4.0, 1440.0 / 4.0);
void main()
{
    vec3 fragPos = texture(gPosition, TexCoords).rgb;
    vec3 normal = normalize(texture(gNormal, TexCoords).rgb);
    vec3 albedo = texture(gAlbedo, TexCoords).rgb;
    vec3 randomVec = normalize(texture(texNoise, TexCoords * noiseScale).xyz);
    
      // 创建TBN矩阵，从切线空间到视图空间
    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);
    vec3 indirectLight = vec3(0.0);
    float ambientIntensity = 0.8;
    for (int i = 0; i < kernelSize; ++i)
    {
         // 获取样本位置
        vec3 samplePos =TBN* samples[i]; // 切线 -> 观察 space
        vec3 sampleVec= samplePos; // 从片段位置到样本位置的向量
        samplePos = fragPos + samplePos * radius;

        // 投影样本位置并且采样纹理，获取纹理上的位置
        vec4 offset = vec4(samplePos, 1.0); 
        offset = projection * offset; // 观察 -> 裁剪 space
        offset.xyz /= offset.w; // 透视划分
        offset.xyz = offset.xyz * 0.5 + 0.5; // 变换到 0.0 - 1.0 范围

        vec2 sampleUV = offset.xy;


        float sampleDepth = texture(gPosition, sampleUV).z;
        if (sampleDepth == 0.0) continue;
        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(fragPos.z - sampleDepth));
        
        float depthDiff = samplePos.z - sampleDepth;
        bool occluded = depthDiff > bias;
        
        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0)
        continue;

        if (!occluded)
        {
            vec3 sampleColor = texture(gAlbedo, sampleUV).rgb;
            float angleWeight = max(dot(normal, normalize(sampleVec)), 0.0);
            indirectLight += sampleColor * angleWeight*rangeCheck ;
        }
        else{
            //遮挡情况需要适当衰减  要不然太亮！！
            indirectLight*=ambientIntensity;
        }

    }

    indirectLight /= float(kernelSize);
    FragColor = indirectLight;
    //FragColor = pow(indirectLight, vec3(1.0 / 2.2));
}
