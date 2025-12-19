// HwInstancedBlackHoleEffect
// 801A7029BD7964B684FAD7CFDBE914E067329F215DC8D9F65BC39E4E0A311239

#include "Common.fxh"

float4x4 Matrices_WorldViewProjection;
float2 TexelOffset;

bool IsTextureEnabled;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_BODY_INPUT
{
    float4 Position : POSITION;
    float4 InstancePosition : TEXCOORD2;
    float4 InstanceDiffuse : TEXCOORD3;
};

struct VS_FRINGE_INPUT
{
    float4 Position : POSITION;
    float4 TexCoord : TEXCOORD;
    float4 InstancePosition : TEXCOORD2;
    float4 InstanceDiffuse : TEXCOORD3;
    float4 InstanceTextureOffset : TEXCOORD4;
    float4 InstanceTextureScale : TEXCOORD5;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Color : TEXCOORD1;
    float4 Position : POSITION;
};

VS_OUTPUT VS_Body(VS_BODY_INPUT input)
{
    VS_OUTPUT output;

    float3x4 instanceMatrix;
    instanceMatrix[0] = float4(1, 0, 0, input.InstancePosition.x);
    instanceMatrix[1] = float4(0, 1, 0, input.InstancePosition.y);
    instanceMatrix[2] = float4(0, 0, 1, input.InstancePosition.z);
    
    float4 worldPos;
    worldPos.x = dot(input.Position, instanceMatrix[0]);
    worldPos.y = dot(input.Position, instanceMatrix[1]);
    worldPos.z = dot(input.Position, instanceMatrix[2]);
    worldPos.w = input.Position.w;
    
    float4 worldViewPos = mul(worldPos, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;
    
    output.TexCoord = float2(0, 0);
    output.Color = input.InstanceDiffuse.rgb;

    return output;
}

VS_OUTPUT VS_Fringe(VS_FRINGE_INPUT input)
{
    VS_OUTPUT output;

    float2x3 uvTransform;
    uvTransform[0] = float3(input.InstanceTextureScale.x, 0.0, input.InstanceTextureOffset.x);
    uvTransform[1] = float3(0.0, input.InstanceTextureScale.y, input.InstanceTextureOffset.y);

    float3 texCoord = float3(input.TexCoord.xy, 1.0);
    output.TexCoord.x = dot(texCoord, uvTransform[0]);
    output.TexCoord.y = dot(texCoord, uvTransform[1]);

    float3x4 instanceMatrix;
    instanceMatrix[0] = float4(1, 0, 0, input.InstancePosition.x);
    instanceMatrix[1] = float4(0, 1, 0, input.InstancePosition.y);
    instanceMatrix[2] = float4(0, 0, 1, input.InstancePosition.z);

    float4 worldPos;
    worldPos.x = dot(input.Position, instanceMatrix[0]);
    worldPos.y = dot(input.Position, instanceMatrix[1]);
    worldPos.z = dot(input.Position, instanceMatrix[2]);
    worldPos.w = input.Position.w;

    float4 worldViewPos = mul(worldPos, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;

    output.Color = input.InstanceDiffuse.rgb;
    
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
        VertexShader = compile vs_3_0 VS_Body();
        PixelShader = compile ps_3_0 PS();
    }

    pass Fringe
    {
        VertexShader = compile vs_3_0 VS_Fringe();
        PixelShader = compile ps_3_0 PS();
    }
}