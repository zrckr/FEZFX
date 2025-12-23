// InvertEffect
// E94EB3BCECA416B9C2B0D70DF3DBDCBABC8A22D5441D37BADEEFFC1DF1995876

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
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float3 inverted = 1.0 - texColor.rgb;
    return float4(inverted, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}