#ifndef COMMON_FXH
#define COMMON_FXH

#define HEX_RGB(hex) float4( \
    (((hex) >> 16) & 0xFF) / 255.0, \
    (((hex) >> 8) & 0xFF) / 255.0, \
    (hex & 0xFF) / 255.0, \
    1.0)

#define HEX_RGBA(hex) float4( \
    (((hex) >> 24) & 0xFF) / 255.0, \
    (((hex) >> 16) & 0xFF) / 255.0, \
    (((hex) >> 8) & 0xFF) / 255.0, \
    ((hex) & 0xFF) / 255.0)

static const float PI = 3.14159274;

static const float TAU = 2.0 * PI;

static const float ALPHA_THRESHOLD = 0.00390625;

static const float LOG2E = 1.44269502;

float CalculateExponentialFog(float distance, float3 density)
{
    float depth = distance * density;
    float depth3 = depth * depth * depth;
    float expFog = exp2(depth3 * LOG2E);
    float fogFactor = 1.0 - (1.0 / expFog);
    return saturate(fogFactor);
}

#endif