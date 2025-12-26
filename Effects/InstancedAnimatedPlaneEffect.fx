// InstancedAnimatedPlaneEffect
// F02CFF9DEBF7418D09E7EC5BA6E9B2EB3E2D1D6C541B959857C10A14BBA80748

#include "BaseEffect.fxh"

float4x4 InstanceData[58];
float IgnoreFog;        // boolean
float SewerHax;         // boolean
float IgnoreShading;    // boolean
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
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float FogFactor : TEXCOORD2;
    float4 Color : TEXCOORD3;
    float2 Flags : TEXCOORD4;
    float2 AnimData : TEXCOORD5;
};

VS_OUTPUT VS_Main(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float3 Position = InstanceData[index][0].xyz;
    float U_Offset = InstanceData[index][0].w;
    float4 Rotation = InstanceData[index][1];
    float2 Scale = InstanceData[index][2].xy;
    float V_Offset = InstanceData[index][2].z;
    float Flags = InstanceData[index][2].w;
    float4 FilterOpacity = InstanceData[index][3];

    float Fullbright = GetFlag(Flags, 1);
    float ClampTexture = GetFlag(Flags, 2);
    float XTextureRepeat = GetFlag(Flags, 4);
    float YTextureRepeat = GetFlag(Flags, 8);

    float3x3 basis = QuaternionToMatrix(Rotation);
    float4x4 xform = float4x4(
        basis[0] * Scale.x, 0,
        basis[1] * Scale.y, 0,
        basis[2], 0,
        Position, 1.0
    );

    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    float2 texCoord = input.TexCoord;
    texCoord.x *= (XTextureRepeat) ? -1 : 1;
    texCoord.y *= (YTextureRepeat) ? -1 : 1;
    output.TexCoord = texCoord * FrameScale + float2(U_Offset, V_Offset);

    output.Normal = normalize(mul(input.Normal, basis));

    float fogFactor = 1.0;
    if (Fog_Type == FOG_TYPE_EXP_SQR)
    {
        fogFactor = ApplyExponentialSquaredFog(worldViewPos.w, Fog_Density);
    }
    else if (Fog_Type == FOG_TYPE_NONE)
    {
        fogFactor = 0.0;
    }
    output.FogFactor = (IgnoreFog) ? 0.0 : fogFactor;

    output.Color = FilterOpacity;
    output.Flags.x = Fullbright;
    output.Flags.y = ClampTexture;
    output.AnimData.x = V_Offset;
    output.AnimData.y = FrameScale.y;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float Fullbright = input.Flags.x;
    float ClampTexture = input.Flags.y;
    float V_Offset = input.AnimData.x;
    float FrameScaleY = input.AnimData.y;

    if (ClampTexture)
    {
        float wrappedV = frac((input.TexCoord.y - V_Offset) / FrameScaleY);
        input.TexCoord.y = wrappedV * FrameScaleY + V_Offset;
    }

    float4 texColor = tex2D(AnimatedSampler, input.TexCoord);
    float alpha = input.Color.a * texColor.a;
    ApplyAlphaTest(alpha);

    float3 litColor = 1.0;
    if (!IgnoreShading && !Fullbright)
    {
        litColor = CalculateLighting(input.Normal, 1.0);
    }

    float3 color = lerp(litColor, 1.0, input.FogFactor);
    if (SewerHax)
    {
        color = (texColor.r < 0.75) ? 0.0 : 1.0;
    }
    color *= texColor.rgb * 0.5;

    return float4(color, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(AnimatedSampler, input.TexCoord);
    float alpha = texColor.a * input.Color.a;
    ApplyAlphaTest(alpha);

    float3 color = texColor.rgb * input.Color.rgb;
    color = lerp(color, Fog_Color, input.FogFactor);

    return float4(color, alpha);
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS_Main();
        PixelShader = compile ps_2_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VS_Main();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
