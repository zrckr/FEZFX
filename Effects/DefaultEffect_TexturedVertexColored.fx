// DefaultEffect_TexturedVertexColored
// 8C85DFBC0C649AABB69DF33454F1CEAB82AD8A6C2171450FC683E7D15124A11A

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : TEXCOORD0;
    float2 TexCoord : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.Color = input.Color;

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    
    float vertexAlpha = input.Color.a * Material_Opacity;
    float texturedAlpha = texColor.a * vertexAlpha;
    float alpha = (AlphaIsEmissive) ? vertexAlpha : texturedAlpha;
    
    float3 materialColor = input.Color.rgb * Material_Diffuse;
    float3 color = texColor.rgb * materialColor;
    
    return float4(color, alpha);
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
