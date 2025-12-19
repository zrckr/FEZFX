// VibratingEffect
// F63DDAEB6F6B5B082029F62DCAA69C022A1471FF07008024719A3CABCCA3886C

#include "Common.fxh"

static const float3 FOG_COLOR = float3(0.0588235296, 0.00392156886, 0.105882354);

float3 Material_Diffuse;
float Material_Opacity;
float4x4 Matrices_WorldViewProjection;
float2 TexelOffset;
float Time;
float Intensity;
float FogDensity;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 TexCoord : TEXCOORD0;
    float Fog : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    // Compute time-based phase
    float3 phase = Time * 50.0 * input.Color.yzx;
    phase.y = (input.Color.y * TAU) - phase.y;
    phase.xz = (input.Color.xz * TAU) + phase.xz;

    // Normalize phase in [0, 1] range
    phase.xz = frac(phase.xz / TAU + 0.5);
    phase.xz = phase.xz * TAU - PI;
    phase.y = frac(phase.y / TAU + 0.5);
    phase.y = phase.y * TAU - PI;

    float4 vibratingPos;
    vibratingPos.x = (sin(phase.y) * Intensity * input.Color.x * 0.125) + input.Position.x;
    vibratingPos.z = (sin(phase.z) * Intensity * input.Color.y * 0.125) + input.Position.z;
    vibratingPos.y = (sin(phase.x) * Intensity * input.Color.z * 0.75);
    vibratingPos.w = input.Position.w;

    float4 worldViewPos = mul(vibratingPos, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;

    output.TexCoord = 1.0;
    output.Fog = CalculateExponentialFog(worldViewPos.w, FogDensity);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 texColor = input.TexCoord.xyz * Material_Diffuse;
    float3 fogDelta = FOG_COLOR - (input.TexCoord.xyz * Material_Diffuse);
    
    float3 color = texColor + (input.Fog * fogDelta);    
    float alpha = input.TexCoord.w * Material_Opacity;

    return float4(color, alpha);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}