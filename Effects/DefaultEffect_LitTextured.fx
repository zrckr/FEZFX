// DefaultEffect_LitTextured
// F2EFE4BF0C543A3BC39D3425E0F2AD8657C1599A5E9E227D16FCBA7577DF5928

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.Normal = normalize(TransformNormalToWorld(input.Normal));

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);

    float alpha = Material_Opacity;
    if (TextureEnabled && !AlphaIsEmissive)
    {
        alpha *= texColor.a;
    }
    ApplyAlphaTest(alpha);

    float3 diffuse = Material_Diffuse;
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
