// RebootPostEffect
// 8D85ED09059CC414C21C013FDD92E968705380AC2064E82556EDE2D440F7447D

#include "Common.fxh"

float3 Material_Diffuse;
float Material_Opacity;
float4x4 PseudoWorldMatrix;
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

    float4 pos = mul(input.Position, PseudoWorldMatrix);
    output.Position = pos + float4(TexelOffset * pos.w, 0, 0);

    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
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