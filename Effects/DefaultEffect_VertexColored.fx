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
    float alpha = input.Color.a * Material_Opacity;
    float3 color = input.Color.rgb * Material_Diffuse;
    
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