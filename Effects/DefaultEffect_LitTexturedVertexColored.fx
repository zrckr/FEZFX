// DefaultEffect_LitTexturedVertexColored
// 36316EC6700D7D3A79ABA5E02852D91B3106EE1E0E4DF956362B8F851B2DD9C6

#include "DefaultEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float4 Color : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Normal = normalize(TransformNormalToWorld(input.Normal));
    output.Color = input.Color;
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float3 normal = input.Normal;

    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float brightness = (Fullbright) ? 1.0 : Emissive;
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 invDiffuse = 1.0 - DiffuseLight;

    float vertexAlpha = input.Color.a * Material_Opacity;
    float texVertexAlpha = texColor.a * vertexAlpha;

    float alphaValue = (!AlphaIsEmissive) ? texVertexAlpha : vertexAlpha;
    float emissiveAlpha = (!AlphaIsEmissive) ? brightness : texColor.a;

    float alpha = (!TextureEnabled) ? vertexAlpha : alphaValue;
    emissiveAlpha = (!TextureEnabled) ? brightness : emissiveAlpha;

    float3 diffuseColor = input.Color.rgb * Material_Diffuse;
    diffuseColor = (TextureEnabled) ? texColor.rgb * diffuseColor : diffuseColor;

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
