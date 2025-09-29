// #version 330 core
// in vec2 TexCoords;
// out vec3 FragColor;

// uniform sampler2D ssdoInput;
// uniform vec2 blurDirection; // (1, 0) = 横向, (0, 1) = 纵向

// void main()
// {
//     float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
//    // float weights[3] = float[](0.227027, 0.1945946, 0.1216216);
//     vec2 texelSize = 1.0 / vec2(textureSize(ssdoInput, 0));
//     vec3 result = texture(ssdoInput, TexCoords).rgb * weights[0];

//     for (int i = 1; i < 5; ++i)
//     {
//         vec2 offset = blurDirection * texelSize * float(i);
//         result += texture(ssdoInput, TexCoords + offset).rgb * weights[i];
//         result += texture(ssdoInput, TexCoords - offset).rgb * weights[i];
//     }

//     FragColor = result;
// }
#version 330 core
in vec2 TexCoords;
out vec3 FragColor;

uniform sampler2D ssdoInput;   // 要模糊的间接光贴图
uniform sampler2D gPosition;      // 深度贴图，用于边缘检测
uniform vec2 blurDirection;    // (1, 0) = 横向, (0, 1) = 纵向

const float depthThreshold = 0.05; // 控制边缘检测灵敏度
const float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
void main()
{
    vec2 texelSize = 1.0 / vec2(textureSize(ssdoInput, 0));
    vec3 result = texture(ssdoInput, TexCoords).rgb * weights[0];
    float centerDepth = texture(gPosition, TexCoords).z;

    for (int i = 1; i < 5; ++i)
    {
        vec2 offset = blurDirection * texelSize * float(i);

        // 采样正方向
        float depthPos = texture(gPosition, TexCoords + offset).z;
        if (abs(centerDepth - depthPos) < depthThreshold)
        {
            result += texture(ssdoInput, TexCoords + offset).rgb * weights[i];
        }

        // 采样负方向
        float depthNeg = texture(gPosition, TexCoords - offset).z;
        if (abs(centerDepth - depthNeg) < depthThreshold)
        {
            result += texture(ssdoInput, TexCoords - offset).rgb * weights[i];
        }
    }

    FragColor = result;
}
