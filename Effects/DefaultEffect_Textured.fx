// DefaultEffect_Textured
// 30647D335B85CD4780FC8AE8712414FDA7528D2E718B7BA6123B4F4C22BBDCF9

#include "DefaultEffect.fxh"

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

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    texColor *= float4(Material_Diffuse, Material_Opacity);
    float3 color = (TextureEnabled) ? texColor.rgb : Material_Diffuse;
    
    float alphaEmissive = (AlphaIsEmissive) ? Material_Opacity : texColor.a;
    float alphaTest = (TextureEnabled) ? alphaEmissive : Material_Opacity;
    clip(alphaTest - ALPHA_THRESHOLD);
    
    return float4(color, alphaTest);
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float luminance = dot(texColor.rgb, LUMINANCE);

    float alpha;
    if (Fullbright)
    {
        alpha = texColor.a;
    }
    else if (AlphaIsEmissive)
    {
        alpha = Emissive;
    }
    else
    {
        alpha = luminance;
    }
    if (!TextureEnabled)
    {
        alpha = 1.0;
    }

    float4 color;
    if (Fullbright)
    {
        color.rgb = alpha * Material_Diffuse * 0.5;
        color.a = alpha * Material_Opacity;
    }
    else
    {
        color.rgb = 0.5;
        color.a = 1.0;
    }

    return color;
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
