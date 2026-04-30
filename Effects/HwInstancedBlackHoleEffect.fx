// HwInstancedBlackHoleEffect
// 801A7029BD7964B684FAD7CFDBE914E067329F215DC8D9F65BC39E4E0A311239

#include "BaseEffect.fxh"

float IsTextureEnabled;     // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_BODY_INPUT
{
    float4 Position : POSITION;
    float4 Data0 : TEXCOORD2;       // Row 1 : Position (xyz), unused (w)
    float4 Data1 : TEXCOORD3;       // Row 2 : Diffuse (xyz), unused (w)
    float4 Data2 : TEXCOORD4;       // Row 3 : Texture matrix position (xy), unused (zw)
    float4 Data3 : TEXCOORD5;       // Row 4 : Texture matrix scale (xy), unused (zw)
};

struct VS_FRINGE_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Data0 : TEXCOORD2;       // Row 1 : Position (xyz), unused (w)
    float4 Data1 : TEXCOORD3;       // Row 2 : Diffuse (xyz), unused (w)
    float4 Data2 : TEXCOORD4;       // Row 3 : Texture matrix position (xy), unused (zw)
    float4 Data3 : TEXCOORD5;       // Row 4 : Texture matrix scale (xy), unused (zw)
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Diffuse : TEXCOORD1;
    float4 Position : POSITION;
};

VS_OUTPUT VS_Body(VS_BODY_INPUT input)
{
    VS_OUTPUT output;

    float4x4 xform = CreateTransform(input.Data0.xyz);
    float4 worldPos = mul(input.Position, xform);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    
    output.Diffuse = input.Data1.xyz;
    output.TexCoord = 0;

    return output;
}

VS_OUTPUT VS_Fringe(VS_FRINGE_INPUT input)
{
    VS_OUTPUT output;

    float3x3 xform2D = CreateTransform2D(input.Data2.xy, input.Data3.xy);
    output.TexCoord = TransformTexCoord(input.TexCoord, xform2D);

    float4x4 xform = CreateTransform(input.Data0.xyz);
    float4 worldPos = mul(input.Position, xform);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Diffuse = input.Data1.xyz;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 color = float4(input.Diffuse, 1.0);
    
    if (IsTextureEnabled != 0.0)
    {
        float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
        color.rgb *= texColor.rgb;
        color.a *= texColor.a;
        ApplyAlphaTest(color.a);
    }
    
    return color;
}

technique TSM2
{
    pass Body
    {
        VertexShader = compile vs_3_0 VS_Body();
        PixelShader = compile ps_3_0 PS();
    }

    pass Fringe
    {
        VertexShader = compile vs_3_0 VS_Fringe();
        PixelShader = compile ps_3_0 PS();
    }
}