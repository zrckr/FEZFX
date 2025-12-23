// MatrixEffect
// FF3080A9952F5C24037F19E24B6EC9141060CE0376DB2DEAE2FAAC20EF86FF14

#include "Common.fxh"

float3 Material_Diffuse;
float Material_Opacity;
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
    
    float alphaTest = texColor.a * Material_Opacity;
    clip(alphaTest - ALPHA_THRESHOLD);
    
    float3 materialDiffuse = (Material_Diffuse * 0.75) + 0.5;
    return float4(texColor.rgb * materialDiffuse, alphaTest);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}