#version 330 core
in vec2 TexCoords;
out float FragColor;

uniform sampler2D ssaoInput;
uniform vec2 blurDirection; // (1, 0) = 横向, (0, 1) = 纵向

void main()
{
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    vec2 texelSize = 1.0 / vec2(textureSize(ssaoInput, 0));
    float result = texture(ssaoInput, TexCoords).r * weights[0];

    for (int i = 1; i < 5; ++i)
    {
        vec2 offset = blurDirection * texelSize * float(i);
        result += texture(ssaoInput, TexCoords + offset).r * weights[i];
        result += texture(ssaoInput, TexCoords - offset).r * weights[i];
    }

    FragColor = result;
}

