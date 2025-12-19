// SkyEffect
// 2BA9F71DF6B17F7E30630C8079588F10757B57CD4E4EC15878B11359EA6F62B7

static const float DISTANCE_THRESHOLD = 1.0 / 84.0;

float4x4 Matrices_WorldViewProjection;
float4x4 Matrices_World;
float3x3 Matrices_Texture;
float3 CenterPosition;
float2 TexelOffset;
float Material_Opacity;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float FadeFactor : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;

    float3 texCoord = float3(input.TexCoord.xy, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;

    float3 world = mul(input.Position, (float4x3)Matrices_World);
    float distanceFromCenter = abs(world.y - CenterPosition.y);
    float fadeFactor = min(pow(distanceFromCenter * DISTANCE_THRESHOLD, 2.0), 1.0);
    output.FadeFactor = 1.0 - fadeFactor;

    return output;
}

float4 PS_P0(VS_OUTPUT input) : COLOR0
{
    float4 color = tex2D(BaseSampler, input.TexCoord);
    color.r = color.a * Material_Opacity;
    color = color.rrrr * input.FadeFactor;
    return color;
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_P0();
    }
}
