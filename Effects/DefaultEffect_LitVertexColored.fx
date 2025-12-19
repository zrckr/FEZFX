// DefaultEffect_LitVertexColored
// FFC3533698B804B7EB0D25CB87B09C60C9FFD2C70DB9E84FF67143FCE17C9F41

float4x4 Matrices_WorldViewProjection;
float4x4 Matrices_WorldInverseTranspose;
float2 TexelOffset;

float3 DiffuseLight;
float3 BaseAmbient;
float3 Eye;
bool SpecularEnabled;
bool Fullbright;
float Emissive;

float3 Material_Diffuse;
float Material_Opacity;
bool AlphaIsEmissive;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float3 Normal : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float4 Color : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    float4 worldViewPos = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;
    
    output.Normal = normalize(mul(input.Normal, (float3x3)Matrices_WorldInverseTranspose));
    output.Color = input.Color;
    
    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float3 normal = input.Normal;
    
    // Calculate ambient contribution
    float brightness = (Fullbright) ? 1.0 : Emissive;
    float3 ambient = saturate(brightness + BaseAmbient);
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 invDiffuse = brightness * (1.0 - DiffuseLight);
    
    // Front lighting
    float normalDotLight = saturate(dot(normal, 1.0));
    float3 frontLighting = normalDotLight * invAmbient + ambient;
    
    // Backface lighting
    float3 backLighting = abs(normal.z) * invAmbient * 0.6 + frontLighting;
    float3 lighting = (normal.z < -0.01) ? backLighting : frontLighting;
    
    // Side lighting
    float3 sideLighting = abs(normal.x) * invAmbient * 0.3 + lighting;
    lighting = saturate((normal.x < -0.01) ? sideLighting : lighting);
    
    // Apply diffuse and vertex color on material
    lighting = DiffuseLight * lighting + invDiffuse;
    float3 color = lighting * input.Color.rgb * Material_Diffuse;
    
    // Calculate specular
    if (SpecularEnabled)
    {
        float3 eyeDir = Eye - float3(0.0, 0.25, 0.0);
        float specular = dot(eyeDir, normal);
        specular = saturate(pow(specular, 8));
        color += specular * 0.5;
    }
    
    // Calculate alpha
    float alpha = input.Color.a * Material_Opacity;

    return float4(color, alpha);
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float brightness = (Fullbright) ? 1.0 : Emissive;
    float3 color = Material_Diffuse * brightness;
    float alpha = Material_Opacity * brightness;

    if (AlphaIsEmissive)
    {
        color = 0.5;
    }
    else
    {
        color *= 0.5;
        alpha = 1.0;
    }
    
    return float4(color, alpha);
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
