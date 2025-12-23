// ZoomInEffect
// 41C180564DAD1048840561B6365431F3A6B19468E6A0549F8D0A667B8611FBE4

#include "Common.fxh"

float3 Material_Diffuse;
float Material_Opacity;
float3x3 Matrices_Texture;
float2 TexelOffset;
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
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    float4 offset = float4(TexelOffset * input.Position.w, 0, 0);
    output.Position = input.Position + offset;
    
    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;
    
    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, saturate(input.TexCoord)); // clamps UV in [0, 1] range
    float alphaTest = texColor.a * Material_Opacity;
    clip(alphaTest - ALPHA_THRESHOLD);

    return float4(texColor.rgb * Material_Diffuse, alphaTest);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}