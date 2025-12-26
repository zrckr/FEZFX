// HwInstancedAnimatedPlaneEffect
// 24D2B0C9DCCD387DABD403B291967AFCD8CED2B7888F1B1C371C4DBFB9C3B547

#include "BaseEffect.fxh"

float IgnoreFog;        // boolean
float IgnoreShading;    // boolean
float SewerHax;         // boolean
float2 FrameScale;

texture AnimatedTexture;
sampler2D AnimatedSampler = sampler_state
{
    Texture = <AnimatedTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 InstanceData0 : TEXCOORD2;   // Position.X, Position.Y, Position.Z, U_Offset
    float4 InstanceData1 : TEXCOORD3;   // Rotation.X, Rotation.Y, Rotation.Z, Rotation.W
    float4 InstanceData2 : TEXCOORD4;   // Scale.X, Scale.Y, V_Offset, Flags
    float4 InstanceData3 : TEXCOORD5;   // Filter.R, Filter.G, Filter.B, Opacity
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float FogFactor : TEXCOORD2;
    float4 Color : TEXCOORD3;           // Filter, Opacity
    float2 TexFlags : TEXCOORD4;        // XTextureRepeat, YTextureRepeat
    float2 FrameData : TEXCOORD5;       // Fullbright, FrameScale.y
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    // Alias inputs from instance matrix
    float3 Position = input.InstanceData0.xyz;
    float2 TexOffset = float2(input.InstanceData0.w, input.InstanceData2.z);
    float4 Rotation = input.InstanceData1;
    float2 Scale = input.InstanceData2.xy;
    float Flags = input.InstanceData2.w;
    float4 Color = input.InstanceData3;

    // Convert bit flags to binary float4 flags
    float4 flags4 = DecodeFlags4(Flags);
    float Fullbright = flags4.x;        // (1 << 0)  =>  x ∊ {0, 1}
    float ClampTexture = flags4.y;      // (1 << 1)  =>  y ∊ {0, 1}
    float XTextureRepeat = flags4.z;    // (1 << 2)  =>  z ∊ {0, 1}
    float YTextureRepeat = flags4.w;    // (1 << 3)  =>  w ∊ {0, 1}

    // Calculate texture coordinates with instance offset
    float2 texCoord = input.TexCoord + TexOffset;
    if (XTextureRepeat)
    {
        texCoord.x = frac(texCoord.x);
    }
    if (YTextureRepeat)
    {
        texCoord.y = frac(texCoord.y);
    }
    if (ClampTexture)
    {
        texCoord = saturate(texCoord);
    }
    output.TexCoord = texCoord;

    // Transform normal
    float3x3 basis = QuaternionToBasis(Rotation);
    output.Normal = mul(input.Normal, basis);

    // Transform position
    float4x4 xform = float4x4(
        basis[0] * Scale.x, 0.0,
        basis[1] * Scale.y, 0.0,
        basis[2] * 1.0, 0.0,
        Position, 1.0
    );
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformWorldToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    // Calculate fog
    float fogFactor;
    if (Fog_Type == FOG_TYPE_EXP_SQR)
    {
        fogFactor = ApplyExponentialSquaredFog(worldViewPos.w, Fog_Density);
    }
    else if (Fog_Type == FOG_TYPE_NONE)
    {
        fogFactor = 1.0;
    }
    output.FogFactor = (IgnoreFog) ? saturate(1.0 - fogFactor) : fogFactor;

    // Set the rest of outputs
    output.Color = Color;
    output.TexFlags = float2(XTextureRepeat, YTextureRepeat);
    output.FrameData = float2(Fullbright, FrameScale.y);

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
