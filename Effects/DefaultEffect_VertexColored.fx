// DefaultEffect_VertexColored
// 2899B01F2494D82D5F258560662D1C4C32C63F3EA0B124B4D6523D031DF50E96

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Color = input.Color;

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 material = float4(Material_Diffuse, Material_Opacity);
    return input.Color * material;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    if (!AlphaIsEmissive)
    {
        return float4(0.5, 0.5, 0.5, 1.0);
    }
    
    float factor = Fullbright ? 1.0 : Emissive;
    float3 color = Material_Diffuse * factor * 0.5;
    float alpha = Material_Opacity * factor;
    
    return float4(color, alpha);
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