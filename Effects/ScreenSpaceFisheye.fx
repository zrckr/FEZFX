// ScreenSpaceFisheye
// AB01A8FB53AE054E345AEEF1E5BAFA5B3699B9E7B787BEA9AD4FDEDB16693A99

float2 Intensity;
float3x3 Matrices_Texture;
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
    
    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    // Center the UV
    float2 centered = (input.TexCoord - 0.5) * 2.0; // [-1, 1] range

    // Fisheye distortion calculation. Order of X and Y matters here!
    float2 distort;
    distort.x = (1.0 - centered.y * centered.y) * Intensity.y;
    distort.y = (1.0 - centered.x * centered.x) * Intensity.x;

    // Subtract offset from original UV
    float2 distortedUV = input.TexCoord - (centered * distort);

    float3 color = tex2D(BaseSampler, distortedUV).rgb;
    return float4(color, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}