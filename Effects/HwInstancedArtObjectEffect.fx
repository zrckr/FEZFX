// HwInstancedArtObjectEffect
// FA04DD1AF77BA1D4DD5C3B35FD9397A2B47679DDA79EFBE13AC62B04B73588BA

#include "BaseEffect.fxh"

DECLARE_TEXTURE(CubemapTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 Data0 : TEXCOORD2;    // Row 1 : Position (xyz), Opacity (w)
    float4 Data1 : TEXCOORD3;    // Row 2 : Scale (xyz), ForceShading (w)
    float4 Data2 : TEXCOORD4;    // Row 3 : Rotation quaternion (xyzw)
    float4 Data3 : TEXCOORD5;    // Row 4 : Hidden sides (frbl => xyzw)
};

struct VS_OUTPUT
{
    float3 Normal : TEXCOORD0;
    float Fog : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float ClipValue : TEXCOORD3;
    float Opacity : TEXCOORD4;
    float ForceShading : TEXCOORD5;
    float4 Position : POSITION0;
};

float ComputeVisibility(float3 normal, float4 hideSides)
{
    if (hideSides[0] != 0.0 && normal.z > 0.5) return -1.0;    // front
    if (hideSides[1] != 0.0 && normal.x > 0.5) return -1.0;    // right
    if (hideSides[2] != 0.0 && normal.z < -0.5) return -1.0;   // back
    if (hideSides[3] != 0.0 && normal.x < -0.5) return -1.0;   // left
    return 1.0;
}

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3x3 basis = QuaternionToMatrix(input.Data2);
    float4x4 xform = CreateTransform(input.Data0.xyz, basis, input.Data1.xyz);
    
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Fog = 1.0 - ApplyFog(output.Position.w);
    output.Normal = mul(input.Normal, basis);
    output.ClipValue = ComputeVisibility(output.Normal, input.Data3);
    
    output.TexCoord = input.TexCoord;
    output.ForceShading = input.Data1.w > 0.5 ? 1.0 : 0.0;
    output.Opacity = input.Data0.w;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    clip(input.ClipValue);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);
    
    float3 light = ComputeLight(input.Normal, texColor.a);
    float3 color = lerp(light, 1.0, input.Fog);

    return float4(color * 0.5, input.Opacity);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    clip(input.ClipValue);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);

    float3 light = texColor.rgb;
    if (input.ForceShading > 0.5)
    {
        light *= ComputeLight(input.Normal, texColor.a);
    }

    float3 color = lerp(light, Fog_Color, input.Fog);

    return float4(color, input.Opacity);
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
