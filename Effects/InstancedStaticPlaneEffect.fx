// InstancedStaticPlaneEffect
// 39BAA693E665A43A94CC188B9CA4CA3DDE0EA913CAFA01392E4157B784EFAC53

#include "BaseEffect.fxh"

float4x4 InstanceData[59];
float IgnoreFog;        // boolean
float SewerHax;         // boolean

texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
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
    float Fullbright : TEXCOORD4;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float3 Position = InstanceData[index][0].xyz;
    float4 Rotation = InstanceData[index][1];
    float2 Scale = InstanceData[index][2].xy;
    float Flags = InstanceData[index][2].z;
    float4 FilterOpacity = InstanceData[index][3];

    float Fullbright = GetFlag(Flags, 1);
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
    output.Normal = basis[2];

    float2 texCoord = input.TexCoord;
    texCoord.x *= (XTextureRepeat) ? -1 : 1;
    texCoord.y *= (YTextureRepeat) ? -1 : 1;
    output.TexCoord = texCoord;

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
    output.Fullbright = Fullbright;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float alpha = input.Color.a * texColor.a;
    ApplyAlphaTest(alpha);

    float3 litColor = CalculateLighting(input.Normal, input.Fullbright);

    float3 color = lerp(litColor, 1.0, input.FogFactor);
    if (SewerHax)
    {
        color = (texColor.r < 0.75) ? 0.0 : 1.0;
    }
    color *= 0.5;

    return float4(color, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
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
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
