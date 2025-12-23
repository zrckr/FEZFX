// ScanlineEffect
// 4C93D5D8870A4D52F2543721E17AD048345A450510250B93276564CAECC992BC

#include "Common.fxh"

float3x3 Matrices_Texture;
float Time;
float Material_Opacity;
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

    output.Position.xy = (TexelOffset * input.Position.w) + input.Position.xy;
    output.Position.zw = input.Position.zw;
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    // Barrel distortion
    float2 offset = input.TexCoord - 0.5;
    float distSq = dot(offset, offset);
    float2 undistorted = (offset * 2.0) + 0.5;
    float distortStrength = pow(abs(distSq), 1.5);
    float2 distortedUV = lerp(input.TexCoord, undistorted, distortStrength);

    // Transform UVs using matrix
    float3 uvw = float3(distortedUV, 1.0);
    float2 uv = mul(uvw, Matrices_Texture).xy;
    float4 texColor = tex2D(BaseSampler, uv);

    // Scanline phase
	const float SCANLINE_FREQ = 300 * PI;
    float scanlinePhase = uv.y * SCANLINE_FREQ + (Time * 2.0);
    float3 phases = scanlinePhase + float3(0.0, 1.0, 2.0);
    phases = frac(phases * (1.0 / TAU) + 0.25) * TAU - PI;	// [-PI, PI] range

    // Taylor series cos(x) approximation: 1 - x²/2! + x⁴/4! - x⁶/6! + x⁸/8!
    float3 x2 = phases * phases;
    float3 cosVal = x2 * 0.000025 - 0.001389;
    cosVal = x2 * cosVal + 0.041667;
    cosVal = x2 * cosVal - 0.5;
    cosVal = x2 * cosVal + 1.0;

    // Apply scanline modulation
    float3 scanline = cosVal * 0.5 + 0.8;	// [0.3, 1.3] range
    float3 color = texColor.rgb * scanline;

    return float4(color, Material_Opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}