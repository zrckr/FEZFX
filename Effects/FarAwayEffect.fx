// FarAwayEffect
// 6BD67ADFAF58B798C67FAA2C6112F91097CD1877399BE2A3C775FF59921128E9

#include "Common.fxh"

float3 Material_Diffuse;
float Material_Opacity;
float ActualOpacity;
float4x4 Matrices_WorldViewProjection;
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

    float4 worldPos = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldPos.w) + worldPos.xy;
    output.Position.zw = worldPos.zw;
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    
    float alphaTest = texColor.a * ActualOpacity;
    clip(alphaTest - ALPHA_THRESHOLD);

    float3 diff = texColor.rgb - Material_Diffuse;
    float3 color = Material_Diffuse + Material_Opacity * diff;
    
    return float4(color, alphaTest);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}