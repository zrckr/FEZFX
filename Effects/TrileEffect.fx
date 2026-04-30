// TrileEffect
// C2D791A5F8E6FB5DDC0436E7391C04BB122CBA71828FE6528FBADD9BA48A3AC8

#include "BaseEffect.fxh"

static const float EMPLACEMENT_CENTER = 0.5;
static const float TIME_FACTOR = 0.1;
static const float ON_TIME = 0.75;

float4 InstanceData[200];
float Blink;            // boolean
float Unstable;         // boolean
float TiltTwoAxis;      // boolean
float Shiny;            // boolean
float ForceShading;     // boolean

DECLARE_TEXTURE(AtlasTexture);

struct VS_INPUT
{
    float4 TemplatePosition : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float Fog : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float4 LightBoost : TEXCOORD3;
    float TimeFactor : TEXCOORD4;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    float4 data = InstanceData[(int)input.InstanceIndex];

    float seed = input.InstanceIndex / 0.229;
    float sinTheta, cosTheta;
    float theta = (Time + seed) * -5.0;
    sincos(theta, sinTheta, cosTheta);

    float sinPhi, cosPhi;
    sincos(data.w, sinPhi, cosPhi);

    float4x4 instanceMatrix = float4x4(
        cosPhi, 0.0, -sinPhi, 0.0,
        0.0, 1.0, 0.0, 0.0,
        sinPhi, 0.0, cosPhi, 0.0,
        data.xyz + EMPLACEMENT_CENTER, 1.0
    );
    
    output.LightBoost = 0.0;
    
    if (Unstable != 0.0)
    {
        if (frac(theta / 12.566370614359) < 0.125)
        {
            cosPhi = cosTheta; 
            sinPhi = sinTheta;
            instanceMatrix[0].xyz = float3(cosTheta * cosPhi, sinTheta, cosTheta * -sinPhi);
            instanceMatrix[1].xyz = float3(-sinTheta * cosPhi, cosTheta, sinTheta * sinPhi);
            instanceMatrix[2].xyz = float3(sinPhi, 0.0, cosPhi);
        }

        output.LightBoost.x = 0.4;  // ambient
        output.LightBoost.y = 0.0;  // diffuse
        output.LightBoost.z = 0.0;  // specular
        output.LightBoost.w = saturate(sinTheta) * saturate(dot(input.TemplatePosition.xyz, 1.0) / 2.0);    // emissive
    }

    if (TiltTwoAxis != 0.0) 
    {	
        instanceMatrix[0][0] = 1.0 / sqrt(2.0) * cosPhi + 1.0 / sqrt(6.0) * sinPhi;
        instanceMatrix[0][1] = 1.0 / sqrt(3.0);
        instanceMatrix[0][2] = 1.0 / sqrt(2.0) * -sinPhi + 1.0 / sqrt(6.0) * cosPhi;
        
        instanceMatrix[1][0] = -2.0 / sqrt(6.0) * sinPhi;
        instanceMatrix[1][1] = 1.0 / sqrt(3.0);
        instanceMatrix[1][2] = -2.0 / sqrt(6.0) * cosPhi;
        
        instanceMatrix[2][0] = -1.0 / sqrt(2.0) * cosPhi + 1.0 / sqrt(6.0) * sinPhi;
        instanceMatrix[2][1] = 1.0 / sqrt(3.0);
        instanceMatrix[2][2] = -1.0 / sqrt(2.0) * -sinPhi + 1.0 / sqrt(6.0) * cosPhi;
    }

    if (Shiny != 0.0)
    {
        output.LightBoost.x = 0.35;     // ambient
        //output.LightBoost.y = 0.75;   // diffuse
        output.LightBoost.z = 0.85;     // specular
    }

    float4 worldPos = mul(input.TemplatePosition, instanceMatrix);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Normal = mul(input.Normal, (float3x3)instanceMatrix);
    output.TexCoord = input.TexCoord;
    output.Fog = saturate(1.0 - ApplyFog(output.Position.w));

    output.TimeFactor = (Blink != 0.0)
        ? (frac(Time * TIME_FACTOR + seed) < ON_TIME) ? 1.0 : 0.0
        : 1.0;

    return output;
}

float3 ComputeLight(VS_OUTPUT input, float alpha)
{
    float ambientBoost = input.LightBoost.x + alpha;
    float emissive = input.LightBoost.y + alpha;

    float3 ambient = PerAxisShading(input.Normal, ambientBoost);
    return ambient * DiffuseLight + emissive * (1.0 - DiffuseLight) * input.TimeFactor;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AtlasTexture, input.TexCoord);
    float3 light = ComputeLight(input, texColor.a);
    float3 color = lerp(light, 1.0, input.Fog);
    return float4(color * 0.5, 1.0);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AtlasTexture, input.TexCoord);
    float specular = ApplySpecular(input.Normal) * input.LightBoost.z;

    float3 color = texColor.rgb + input.LightBoost.w + specular;
    if (ForceShading != 0.0)
    {
        color *= ComputeLight(input, texColor.a);
    }
    color = lerp(color, Fog_Color, input.Fog);

    return float4(color, Material_Opacity);
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
