#ifndef BASE_EFFECT_FXH
#define BASE_EFFECT_FXH

//------------------------------------------------------------------------------
// MACROS
//------------------------------------------------------------------------------

#define RGB(hex) float3( \
    ((hex >> 16) & 0xFF) / 255.0, \
    ((hex >> 8) & 0xFF) / 255.0, \
    (hex & 0xFF) / 255.0 \
)

#define RGBA(hex) float4( \
    ((hex >> 24) & 0xFF) / 255.0, \
    ((hex >> 16) & 0xFF) / 255.0, \
    ((hex >> 8) & 0xFF) / 255.0, \
    (hex & 0xFF) / 255.0 \
)

//------------------------------------------------------------------------------
// CONSTANTS
//------------------------------------------------------------------------------

static const float PI = 3.14159274;

static const float INV_PI = 1.0 / PI;

static const float TAU = 2.0 * PI;

static const float INV_TAU = 1.0 / TAU;

static const float E = 2.71828183;

static const float LOG2E = 1.44269502;

static const float ALPHA_THRESHOLD = 1.0 / 256.0;

static const float4 WHITE = RGBA(0xFFFFFFFF);

static const float4 TRANSPARENT = RGBA(0x00000000);

//------------------------------------------------------------------------------
// FOG SEMANTICS
//------------------------------------------------------------------------------

static const float FOG_TYPE_NONE = 0.0;
static const float FOG_TYPE_EXP = 1.0;
static const float FOG_TYPE_EXP_SQR = 2.0;
static const float FOG_TYPE_LINEAR = 3.0;

float Fog_Type;

float3 Fog_Color;

float Fog_Density;

float ApplyExponentialSquaredFog(float distance, float density)
{
    float depth3 = pow(distance * density, 3);
    float expFog = exp2(depth3 * LOG2E);
    return 1.0 - (1.0 / expFog);
}

//------------------------------------------------------------------------------
// MATRIX SEMANTICS (XNA ROW-MAJOR CONVENTION)
//------------------------------------------------------------------------------

static const float4x4 MATRIX_IDENTITY = float4x4(
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
);

float4x4 Matrices_WorldViewProjection;

float4x4 Matrices_WorldInverseTranspose;

float4x4 Matrices_World;

float3x3 Matrices_Texture;

float4x4 Matrices_ViewProjection;

float4 TransformPositionToClip(float4 position)
{
    return mul(position, Matrices_WorldViewProjection);
}

float3 TransformNormalToWorld(float3 normal)
{
    return mul(normal, (float3x3)Matrices_WorldInverseTranspose);
}

float4 TransformNormalToWorld(float4 normal)
{
    return mul(normal, (float3x4)Matrices_WorldInverseTranspose);
}

float4 TransformPositionToWorld(float4 position)
{
    return mul(position, Matrices_World);
}

float4 TransformPosition(float4 position, float4x4 transform)
{
    return mul(position, transform);
}

float2 TransformTexCoord(float2 texCoord)
{
    return mul(float3(texCoord, 1.0), Matrices_Texture).xy;
}

float2 TransformTexCoord(float2 texCoord, float3x3 matricesTexture)
{
    return mul(float3(texCoord, 1.0), matricesTexture).xy;
}

float4 TransformWorldToClip(float4 worldPosition)
{
    return mul(worldPosition, Matrices_ViewProjection);
}

//------------------------------------------------------------------------------
// MATERIAL SEMANTICS
//------------------------------------------------------------------------------

float3 Material_Diffuse;

float Material_Opacity;

float4 ApplyMaterialDefault(float3 color, float alpha)
{
    color *= Material_Diffuse;
    alpha *= Material_Opacity;
    clip(alpha - ALPHA_THRESHOLD);
    return float4(color, alpha);
}

void ApplyAlphaTest(float alpha)
{
    clip(alpha - ALPHA_THRESHOLD);
}

//------------------------------------------------------------------------------
// BASE EFFECT SEMANTICS
//------------------------------------------------------------------------------

float AspectRatio;

float2 TexelOffset;

float Time;

float3 BaseAmbient;

float3 Eye;

float3 DiffuseLight;

float3 EyeSign;

float3 LevelCenter;

float4 ApplyTexelOffset(float4 position)
{
    return float4(position.xy + (TexelOffset * position.w), position.zw);
}

float4 ApplyTexelOffset(float4 position, float2 offset)
{
    return float4(position.xy + (offset * position.w), position.zw);
}

float3 CalculateLighting(float3 normal, float brightness )
{
    float3 ambient = saturate(brightness + BaseAmbient);
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 invDiffuse = brightness  * (1.0 - DiffuseLight);

    // Front lighting for surfaces lit directly
    float ndotl = saturate(dot(normal, 1.0));
    float3 frontLighting = ndotl * invAmbient + ambient;

    // Back lighting for surfaces facing away (60% contribution)
    float3 backLighting = abs(normal.z) * invAmbient * 0.6 + frontLighting;
    float3 lighting = (normal.z < -0.01) ? backLighting : frontLighting;

    // Side lighting for surfaces facing left/right (30% contribution)
    float3 sideLighting = abs(normal.x) * invAmbient * 0.3 + lighting;
    lighting = saturate((normal.x < -0.01) ? sideLighting : lighting);

    return DiffuseLight * lighting + invDiffuse;
}

float ApplySpecular(float3 normal)
{
    float3 eyeDir = Eye - float3(0.0, 0.25, 0.0);
    float specular = dot(eyeDir, normal);
    return saturate(pow(specular, 8)) * 0.5;
}

#endif // BASE_EFFECT_FXH