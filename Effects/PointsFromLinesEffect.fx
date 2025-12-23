// PointsFromLinesEffect
// 9D7C1C7A57A5F76C011AA57BE9E305BEE55943580BB06F0CBCADF866DA6A843E

float4x4 Matrices_WorldViewProjection;
float2 TexelOffset;
float Material_Opacity;

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
    output.Position.x += sign(input.Color.a) * -TexelOffset.x * 4.0;
    output.Color = float4(input.Color.rgb, Material_Opacity);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    return input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}