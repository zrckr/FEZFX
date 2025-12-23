// MapEffect
// 4FE19FCEEC9263809FBE71E54A752676CE32719076062E7B3F7605BA4FA22E8A

float3 Material_Diffuse;
float Material_Opacity;
float4x4 Matrices_WorldViewProjection;
float2 TexelOffset;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    output.Position = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy += TexelOffset * output.Position.w;
    output.Color = input.Color;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    clip(input.Color.a * Material_Opacity - 0.01);
    float4 material = float4(Material_Diffuse, Material_Opacity * Material_Opacity);
    return input.Color * material;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}