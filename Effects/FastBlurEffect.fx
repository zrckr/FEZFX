// FastBlurEffect
// D425FF55A5564CA9ACDAA0B19989939F9D2AC33A88C40CE570BE157AE5538F0A

float Weights[5];
float Offsets[5];
float2 TexelSize;
float BlurWidth;
float2 Direction;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float2 BlurStep : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    output.Position = input.Position;
    output.TexCoord = input.TexCoord;
    output.BlurStep = Direction * TexelSize * BlurWidth;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float2 uv = input.TexCoord;
    float2 step = input.BlurStep;

    // 9-tap Gaussian blur
    float4 result = tex2D(BaseSampler, uv) * Weights[0];
    for (int i = 1; i < 5; i++)
    {
        float offset = i * 2.0 - 0.5 + Offsets[i];
        result += tex2D(BaseSampler, uv - step * offset) * Weights[i];
        result += tex2D(BaseSampler, uv + step * offset) * Weights[i];
    }

    return result;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}