// DefaultEffect_LitTextured
// F2EFE4BF0C543A3BC39D3425E0F2AD8657C1599A5E9E227D16FCBA7577DF5928

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.Normal = normalize(TransformNormalToWorld(input.Normal));

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float3 normal = input.Normal;

    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float brightness = (Fullbright) ? 1.0 : Emissive;
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 invDiffuse = 1.0 - DiffuseLight;

    float alphaValue = texColor.a * Material_Opacity;
    float alphaEmissive = (AlphaIsEmissive) ? Material_Opacity : alphaValue;
    float alpha = (TextureEnabled) ? alphaEmissive : Material_Opacity;
    ApplyAlphaTest(alpha);

    float3 diffuseColor = texColor.rgb * Material_Diffuse;
    diffuseColor = (TextureEnabled) ? diffuseColor : Material_Diffuse;

    float emissiveAlpha = texColor.a;
    emissiveAlpha = (AlphaIsEmissive) ? emissiveAlpha : brightness;
    emissiveAlpha = (TextureEnabled) ? emissiveAlpha : brightness;

    float3 ambient = saturate(emissiveAlpha + BaseAmbient);
    float3 ambientColor = emissiveAlpha * invDiffuse;

    float ndotl = saturate(dot(normal, 1.0));
    float3 frontLighting = ndotl * invAmbient + ambient;

    float3 backLighting = abs(normal.z) * invAmbient * 0.6 + frontLighting;
    float3 lighting = (normal.z >= -0.01) ? frontLighting : backLighting;

    float3 sideLighting = abs(normal.x) * invAmbient * 0.3 + lighting;
    lighting = saturate((normal.x >= -0.01) ? lighting : sideLighting);

    float3 litColor = lighting * DiffuseLight + ambientColor;
    float3 color = diffuseColor * litColor;

    if (SpecularEnabled)
    {
        float3 eyeDir = Eye - float3(0, 0.25, 0);
        float specular = dot(eyeDir, normal);
        specular = saturate(pow(specular, 8));
        color += specular * 0.5;
    }

    return float4(color, alpha);
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float luminance = dot(texColor.rgb, LUMINANCE);

    float alpha;
    if (Fullbright)
    {
        alpha = texColor.a;
    }
    else if (AlphaIsEmissive)
    {
        alpha = Emissive;
    }
    else
    {
        alpha = luminance;
    }
    if (!TextureEnabled)
    {
        alpha = 1.0;
    }

    float4 color;
    if (Fullbright)
    {
        color.rgb = alpha * Material_Diffuse * 0.5;
        color.a = alpha * Material_Opacity;
    }
    else
    {
        color.rgb = 0.5;
        color.a = 1.0;
    }

    return color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }

    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }
}
