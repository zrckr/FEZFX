#ifndef DEFAULT_EFFECT_FXH
#define DEFAULT_EFFECT_FXH

#include "BaseEffect.fxh"

static const float3 LUMINANCE = 1.0 / 3.0;

float AlphaIsEmissive;  // boolean
float Fullbright;       // boolean
float Emissive;

float TextureEnabled;   // boolean
float SpecularEnabled;  // boolean

texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

float3 ApplyLitShading(float3 normal, float brightness, float3 diffuse)
{
    float3 litColor = CalculateLighting(normal, brightness);
    float3 color = litColor * diffuse;

    if (SpecularEnabled)
    {
        color += ApplySpecular(normal);
    }

    return color;
}

float4 CalculatePrePassTextured(float4 texColor)
{
    float brightness;
    if (Fullbright)
    {
        brightness = texColor.a;
    }
    else if (AlphaIsEmissive)
    {
        brightness = Emissive;
    }
    else
    {
        brightness = dot(texColor.rgb, LUMINANCE);
    }
    
    if (!TextureEnabled)
    {
        brightness = 1.0;
    }

    float4 color;
    if (Fullbright)
    {
        color.rgb = brightness * Material_Diffuse * 0.5;
        color.a = brightness * Material_Opacity;
    }
    else
    {
        color.rgb = 0.5;
        color.a = 1.0;
    }

    return color;
}

float4 CalculatePrePassVertexColored()
{
    float brightness = (Fullbright) ? 1.0 : Emissive;

    float4 color;
    if (AlphaIsEmissive)
    {
        color.rgb = brightness * Material_Diffuse * 0.5;
        color.a = brightness * Material_Opacity;
    }
    else
    {
        color.rgb = 0.5;
        color.a = 1.0;
    }

    return color;
}

#endif // DEFAULT_EFFECT_FXH