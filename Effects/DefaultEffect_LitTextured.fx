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
    float brightness = (Fullbright) ? 1.0 : Emissive;

    float alphaValue = texColor.a * Material_Opacity;
    float alphaEmissive = (AlphaIsEmissive) ? Material_Opacity : alphaValue;
    float alpha = (TextureEnabled) ? alphaEmissive : Material_Opacity;
    ApplyAlphaTest(alpha);

    float3 diffuseColor = texColor.rgb * Material_Diffuse;
    diffuseColor = (TextureEnabled) ? diffuseColor : Material_Diffuse;

    float emissiveAlpha = texColor.a;
    emissiveAlpha = (AlphaIsEmissive) ? emissiveAlpha : brightness;
    emissiveAlpha = (TextureEnabled) ? emissiveAlpha : brightness;

    float3 litColor = CalculateLighting(input.Normal, brightness);
    float3 color = litColor * diffuseColor;

    if (SpecularEnabled)
    {
        color += ApplySpecular(input.Normal);
    }

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
