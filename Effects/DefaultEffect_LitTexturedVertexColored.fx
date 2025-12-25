// DefaultEffect_LitTexturedVertexColored
// 36316EC6700D7D3A79ABA5E02852D91B3106EE1E0E4DF956362B8F851B2DD9C6

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float4 Color : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Normal = normalize(TransformNormalToWorld(input.Normal));
    output.Color = input.Color;
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);

    float alpha = input.Color.a * Material_Opacity;
    if (TextureEnabled && !AlphaIsEmissive)
    {
        alpha *= texColor.a;
    }

    float3 diffuse = input.Color.rgb * Material_Diffuse;
    if (TextureEnabled)
    {
        diffuse *= texColor.rgb;
    }

    float brightness = (Fullbright) ? 1.0 : Emissive;
    if (TextureEnabled && AlphaIsEmissive)
    {
        brightness = texColor.a;
    }

    float3 color = ApplyLitShading(input.Normal, brightness, diffuse);

    return float4(color, alpha);
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    return CalculatePrePassTextured(texColor);
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
