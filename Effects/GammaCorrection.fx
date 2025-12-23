// GammaCorrection
// C66DCEA588F5465A1ED8465A55EAD038312BA4CFCE7B056E9E8A7B8F2A38FA0B

float Brightness;
float2 TexelOffset;
texture MainBufferTexture;

sampler2D MainBufferSampler = sampler_state
{
    Texture = <MainBufferTexture>;
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
    float4 texColor = tex2D(MainBufferSampler, input.TexCoord);
	float gamma = 1.0 / (0.5 + Brightness);
	float3 corrected = pow(abs(texColor.rgb), gamma);
	float darkening = (Brightness - 0.5) * 0.25;
	
	float3 color = saturate(corrected + darkening);
	return float4(color, 1.0);
}

technique TSM2
{
    pass GammaCorrect
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}