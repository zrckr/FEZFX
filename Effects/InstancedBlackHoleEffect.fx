// InstancedBlackHoleEffect
// 114B5D3E88D90F7E4DD43E17063685643CB380F20ED4982A0F9F479C67763477

#include "BaseEffect.fxh"

// Row 1 : Position (xyz), unused (w)
// Row 2 : Diffuse (xyz), unused (w)
// Row 3 : Texture matrix position (xy), unused (zw)
// Row 4 : Texture matrix scale (xy), unused (zw)
float4x4 InstanceData[60];

float IsTextureEnabled;     // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_BODY_INPUT
{
    float4 Position : POSITION;
    float InstanceIndex : TEXCOORD0;
};

struct VS_FRINGE_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Diffuse : TEXCOORD1;
    float4 Position : POSITION;
    float InstanceIndex : TEXCOORD2;
};

VS_OUTPUT VS_Body(VS_BODY_INPUT input)
{
    VS_OUTPUT output;
    float4x4 data = InstanceData[(int)input.InstanceIndex];

    float4x4 xform = CreateTransform(data[0].xyz);
    float4 worldPos = mul(input.Position, xform);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    
    output.Diffuse = data[1].xyz;
    output.TexCoord = 0.0;
    output.InstanceIndex = input.InstanceIndex;

    return output;
}

VS_OUTPUT VS_Fringe(VS_FRINGE_INPUT input)
{
    VS_OUTPUT output;
    float4x4 data = InstanceData[(int)input.InstanceIndex];

    float3x3 xform2D = CreateTransform2D(data[2].xy, data[3].xy);
    output.TexCoord = TransformTexCoord(input.TexCoord, xform2D);
    
    float4x4 xform = CreateTransform(data[0].xyz);
    float4 worldPos = mul(input.Position, xform);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Diffuse = data[1].xyz;
    output.InstanceIndex = input.InstanceIndex;
    
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
        VertexShader = compile vs_2_0 VS_Body();
        PixelShader = compile ps_2_0 PS();
    }

    pass Fringe
    {
        VertexShader = compile vs_2_0 VS_Fringe();
        PixelShader = compile ps_2_0 PS();
    }
}
