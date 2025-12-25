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

#endif // DEFAULT_EFFECT_FXH