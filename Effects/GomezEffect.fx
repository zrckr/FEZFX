// GomezEffect
// E7E874FBD447516974FB518CE3131179769605707DF3AA455BF857CEA2EAE606

#include "BaseEffect.fxh"

static const float HAT_THRESHOLD = 31.0 / 80.0;     // approx

float NoMoreFez;    // boolean
float Silhouette;   // boolean
float ColorSwap;    // boolean
float Background;

float3 RedSwap;
float3 BlackSwap;
float3 WhiteSwap;
float3 YellowSwap;
float3 GraySwap;

texture AnimatedTexture;
sampler2D AnimatedSampler = sampler_state
{
    Texture = <AnimatedTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float FogFactor : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float HatOffset : TEXCOORD3;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldPos = TransformPositionToWorld(input.Position);
    worldPos = ApplyEyeParallax(worldPos);

    float4 worldViewPos = TransformWorldToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    
    output.HatOffset = input.TexCoord.y * 2.0 - HAT_THRESHOLD;
    
    float fogFactor;
    if (Fog_Type == FOG_TYPE_EXP_SQR)
    {
        fogFactor = ApplyExponentialSquaredFog(worldViewPos.w, Fog_Density);
    }
    else if (Fog_Type == FOG_TYPE_NONE)
    {
        fogFactor = 0.0;
    }
    output.FogFactor = saturate(fogFactor);

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(AnimatedSampler, input.TexCoord);

    ApplyAlphaTest(texColor.a * Material_Opacity);
    if (NoMoreFez && input.HatOffset < 0)
    {
        clip(texColor.r - 0.5);
        clip(texColor.g - 0.25);
        clip(texColor.b - 0.5);
    }

    float3 color = DiffuseLight * 0.5;
    float alpha = texColor.a * Material_Opacity;
    alpha = (alpha >= 0.0) ? 1.0 : -1.0;

    return float4(color, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(AnimatedSampler, input.TexCoord);

    float3 color = texColor.rgb;
    float alpha = texColor.a * Material_Opacity;
    
    if (ColorSwap)
    {    
        if (texColor.r > 0.75)
        {
            color = WhiteSwap;
        }
        else
        {
            color = GraySwap;
        }

        if (texColor.b < 0.5)
        {
            color = YellowSwap;
        }
        if (texColor.g < 0.5)
        {
            color = RedSwap;  
        }
        if (texColor.r < 0.5)
        {
            color = BlackSwap;
        }
    }
    
    ApplyAlphaTest(alpha);
    if (NoMoreFez && input.HatOffset < 0)
    {
        clip(color.r - 0.5);
        clip(color.g - 0.25);
        clip(color.b - 0.5);
    }

    if (Silhouette)
    {
        color = 0.0;
        alpha *= 0.5;
    }

    color *= (1.0 - 0.5 * Background);
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
