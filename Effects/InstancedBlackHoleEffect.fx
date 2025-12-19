// InstancedBlackHoleEffect
// 114B5D3E88D90F7E4DD43E17063685643CB380F20ED4982A0F9F479C67763477

#include "Common.fxh"

float4x4 InstanceData[60];
float4x4 Matrices_WorldViewProjection;
float2 TexelOffset;

float IsTextureEnabled;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_BODY_INPUT
{
    float4 Position : POSITION;
    float InstanceIndex : TEXCOORD;
};

struct VS_FRINGE_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Color : TEXCOORD1;
    float4 Position : POSITION;
    float InstanceIndex : TEXCOORD2;
};

VS_OUTPUT VS_Body(VS_BODY_INPUT input)
{
    VS_OUTPUT output;

    int index = floor(input.InstanceIndex);
    float4 InstancePosition = InstanceData[index][0];
    float4 InstanceDiffuse = InstanceData[index][1];

    float3x4 instanceMatrix;
    instanceMatrix[0] = float4(1, 0, 0, InstancePosition.x);
    instanceMatrix[1] = float4(0, 1, 0, InstancePosition.y);
    instanceMatrix[2] = float4(0, 0, 1, InstancePosition.z);

    float4 worldPos;
    worldPos.x = dot(input.Position, instanceMatrix[0]);
    worldPos.y = dot(input.Position, instanceMatrix[1]);
    worldPos.z = dot(input.Position, instanceMatrix[2]);
    worldPos.w = input.Position.w;

    float4 worldViewPos = mul(worldPos, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;

    output.TexCoord = float2(0, 0);
    output.Color = InstanceDiffuse.rgb;
    output.InstanceIndex = input.InstanceIndex;

    return output;
}

VS_OUTPUT VS_Fringe(VS_FRINGE_INPUT input)
{
    VS_OUTPUT output;

    int index = floor(input.InstanceIndex);
    float4 InstancePosition = InstanceData[index][0];
    float4 InstanceDiffuse = InstanceData[index][1];
    float4 InstanceTextureOffset = InstanceData[index][2];
    float4 InstanceTextureScale = InstanceData[index][3];
    
    float2x3 uvTransform;
    uvTransform[0] = float3(InstanceTextureScale.x, 0.0, InstanceTextureOffset.x);
    uvTransform[1] = float3(0.0, InstanceTextureScale.y, InstanceTextureOffset.y);

    float3 texCoord = float3(input.TexCoord.xy, 1.0);
    output.TexCoord.x = dot(texCoord, uvTransform[0]);
    output.TexCoord.y = dot(texCoord, uvTransform[1]);

    float3x4 instanceMatrix;
    instanceMatrix[0] = float4(1, 0, 0, InstancePosition.x);
    instanceMatrix[1] = float4(0, 1, 0, InstancePosition.y);
    instanceMatrix[2] = float4(0, 0, 1, InstancePosition.z);

    float4 worldPos;
    worldPos.x = dot(input.Position, instanceMatrix[0]);
    worldPos.y = dot(input.Position, instanceMatrix[1]);
    worldPos.z = dot(input.Position, instanceMatrix[2]);
    worldPos.w = input.Position.w;

    float4 worldViewPos = mul(worldPos, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;

    output.Color = InstanceDiffuse.rgb;
    output.InstanceIndex = input.InstanceIndex;
    
    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 output;
    
    if (IsTextureEnabled)
    {
        float4 texColor = tex2D(BaseSampler, input.TexCoord);
        output.rgb = texColor.rgb * input.Color;
        output.a = texColor.a;
        clip(output.a - ALPHA_THRESHOLD);
    }
    else
    {
        output = float4(input.Color, 1.0);
    }
    
    return output;
}

technique TSM2
{
    pass Body
    {
        VertexShader = compile vs_2_0 VS_Body();
        PixelShader = compile ps_2_0 PS();
    }

    pass Fringe
    {
        VertexShader = compile vs_2_0 VS_Fringe();
        PixelShader = compile ps_2_0 PS();
    }
}
