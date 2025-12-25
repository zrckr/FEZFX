// DefaultEffect_LitVertexColored
// FFC3533698B804B7EB0D25CB87B09C60C9FFD2C70DB9E84FF67143FCE17C9F41

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float3 Normal : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float4 Color : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Normal = normalize(TransformNormalToWorld(input.Normal));
    output.Color = input.Color;

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float alpha = input.Color.a * Material_Opacity;
    float3 diffuse = input.Color.rgb * Material_Diffuse;
    float brightness = (Fullbright) ? 1.0 : Emissive;
    float3 color = ApplyLitShading(input.Normal, brightness, diffuse);

    return float4(color, alpha);
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    return CalculatePrePassVertexColored();
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }

    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }
}
