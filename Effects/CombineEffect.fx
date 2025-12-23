// CombineEffect
// EC7FD1032031BC9352447B5964B635E282D7E9B94CEDA61070B909B99C62C688

float4x4 LeftFilter;
float4x4 RightFilter;
float RedGamma;
float2 TexelOffset;
texture LeftTexture;
texture RightTexture;

sampler2D LeftSampler = sampler_state
{
    Texture = <LeftTexture>;
};

sampler2D RightSampler = sampler_state
{
    Texture = <RightTexture>;
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
    float4 leftColor = tex2D(LeftSampler, input.TexCoord);
    float4 rightColor = tex2D(RightSampler, input.TexCoord);

    float3 leftFiltered = mul((float3x3)LeftFilter, leftColor.rgb);
    float3 rightFiltered = mul((float3x3)RightFilter, rightColor.rgb);

    float3 combined = leftFiltered + rightFiltered;
    float redGammaCorrected = pow(abs(combined.r), 1.0 / RedGamma);
    float alpha = max(leftColor.a, rightColor.a);

    return float4(redGammaCorrected, combined.gb, alpha);
}

technique ShaderModel2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}