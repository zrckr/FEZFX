// SplitCollectorEffect
// 52B68E022A1F74CD272C86E9C5E13418C9FA76F29BA56F2D0B33A593FFFD1B0C

float3 Material_Diffuse;
float Material_Opacity;
float VaryingOpacity;
float4x4 Matrices_World;
float4x4 Matrices_ViewProjection;
float2 TexelOffset;
float Offset;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 TexCoord : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 offsetDir = input.TexCoord.xyz * 2.0 - 1.0;
    float4 worldPos = mul(input.Position, Matrices_World);
    float4 offsetPos = float4(worldPos.xyz + Offset * offsetDir, worldPos.w);

    output.Position = mul(offsetPos, Matrices_ViewProjection);
    output.Position.xy += TexelOffset * output.Position.w;
    output.TexCoord = input.TexCoord * float4(2, 2, 2, 1) + float4(-1, -1, -1, 0);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float opacity;
    if (input.TexCoord.w < 0.25)
    {
        opacity = saturate(0.125 * Material_Opacity * VaryingOpacity);
    }
    else if (input.TexCoord.w < 0.5)
    {
        opacity = saturate(Material_Opacity * VaryingOpacity);
    }
    else if (input.TexCoord.w < 0.75)
    {
        opacity = saturate(0.125 * Material_Opacity);
    }
    else
    {
        opacity = Material_Opacity;
    }

    return float4(Material_Diffuse, opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}