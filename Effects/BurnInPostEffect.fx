// BurnInPostEffect
// 42F99AA09C24C293A44E519631A57B3DA30A358692D099026E04B4907DE07AD0

#include "BaseEffect.fxh"

static const float OLD_FRAME_MIX = 0.75;

float3 AcceptColor;

DECLARE_TEXTURE(NewFrameTexture);
DECLARE_TEXTURE(OldFrameTexture);

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

    output.Position = ApplyTexelOffset(input.Position);
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 newFrame = SAMPLE_TEXTURE(NewFrameTexture, input.TexCoord);
    float4 oldFrame = SAMPLE_TEXTURE(OldFrameTexture, input.TexCoord);

    // Create new frame factor
    float3 invDiff = 1.0 - abs(AcceptColor - newFrame.rgb);
    float combine = invDiff.r * invDiff.g * invDiff.b;
    float3 newFrameFactor = pow(combine, 2.0) * AcceptColor;

    // Blend new matched color with old frame color
    float3 newContribution = newFrameFactor * (1.0 - OLD_FRAME_MIX);
    float3 color = oldFrame.rgb * OLD_FRAME_MIX + newContribution;

    return float4(color, 1.0);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}