// SewerHaxEffect
// 794B81B88AEAFD49057C4E8CE8A7770B9BA4A0775C194B505162593EF4BC040F

#include "Common.fxh"

static const float4 DARK_COLOR = HEX_RGB(0x204631);
static const float4 LIGHT_COLOR = HEX_RGB(0x527F39);

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
    float luminance = texColor.r * texColor.r;
    return (luminance <= 0.0) ? DARK_COLOR : LIGHT_COLOR;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}