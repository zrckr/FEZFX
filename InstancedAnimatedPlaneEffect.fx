// InstancedAnimatedPlaneEffect.fx
// Reconstructed from SM2 bytecode assembly

// ----- Shared Parameters -----
float4x4 Matrices_WorldViewProjection;
float4x4 InstanceData[58]; // Row-major XNA format instanced data
float2 TexelOffset;
float2 FrameScale;
float3 Eye;
float3 EyeSign;
float3 LevelCenter;

// ----- Fog Parameters -----
float Fog_Type;
float Fog_Density;
float3 Fog_Color;
float IgnoreFog;

// ----- Lighting Parameters -----
float3 DiffuseLight;
float3 BaseAmbient;
float IgnoreShading;
float SewerHax;

// ----- Textures -----
texture2D BaseTexture;
sampler2D AnimatedSampler = sampler_state
{
    Texture = <BaseTexture>;
};

// ----- Vertex Shader Input -----
struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

// ----- Vertex Shader Output -----
struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float FogAmount : TEXCOORD2;
    float4 Filter : TEXCOORD3;
    float2 Flags : TEXCOORD4;
    float2 AnimData : TEXCOORD5;
};

// ----- Pixel Shader Output -----
struct PS_OUTPUT_PRE
{
    float4 Color : COLOR0;
};

struct PS_OUTPUT_MAIN
{
    float4 Color : COLOR0;
};

// ----- Quaternion to Rotation Matrix -----
float3x3 QuaternionToMatrix(float4 q)
{
    float xx = q.x * q.x;
    float yy = q.y * q.y;
    float zz = q.z * q.z;

    float xy = q.x * q.y;
    float xz = q.x * q.z;
    float xw = q.x * q.w;

    float yz = q.y * q.z;
    float yw = q.y * q.w;

    float zw = q.z * q.w;

    float3x3 result;
    result[0] = float3(1.0 - 2.0 * (yy + zz), 2.0 * (xy + zw), 2.0 * (xz - yw));
    result[1] = float3(2.0 * (xy - zw), 1.0 - 2.0 * (xx + zz), 2.0 * (yz + xw));
    result[2] = float3(2.0 * (xz + yw), 2.0 * (yz - xw), 1.0 - 2.0 * (xx + yy));

    return result;
}

// ----- Extract Flag Bits -----
bool GetFlag(float flags, float bit)
{
    // Extracts individual bits from flags value
    float flagValue = floor(flags);
    float divisor = bit * 0.5;
    float divided = flagValue / divisor;
    float fraction = frac(divided);
    return (frac(fraction * 0.5) >= 0.5);
}

// ----- Vertex Shader -----
VS_OUTPUT VS_Main(VS_INPUT input)
{
    VS_OUTPUT output;

    // Get instance index (floor of InstanceIndex value)
    int instanceIndex = floor(input.InstanceIndex) * 4;

    // Extract instance data from matrix (row-major XNA format)
    // Row 0: Position.xyz, U_Offset
    float3 instancePosition = InstanceData[instanceIndex + 0].xyz;
    float uOffset = InstanceData[instanceIndex + 0].w;

    // Row 1: Rotation (quaternion)
    float4 instanceRotation = InstanceData[instanceIndex + 1];

    // Row 2: Scale.xy, V_Offset, Flags
    float2 instanceScale = InstanceData[instanceIndex + 2].xy;
    float vOffset = InstanceData[instanceIndex + 2].z;
    float flags = InstanceData[instanceIndex + 2].w;

    // Row 3: Filter.xyz, Opacity
    float4 instanceFilter = InstanceData[instanceIndex + 3];

    // Extract flag bits
    float fullbrightFlag = GetFlag(flags, 1.0) ? 1.0 : 0.0;      // Fullbright (1)
    float clampTextureFlag = GetFlag(flags, 2.0) ? 1.0 : 0.0;    // ClampTexture (2)
    float xRepeatFlag = GetFlag(flags, 4.0) ? 1.0 : 0.0;         // XTextureRepeat (4)
    float yRepeatFlag = GetFlag(flags, 8.0) ? 1.0 : 0.0;         // YTextureRepeat (8)

    // Build rotation matrix from quaternion
    float3x3 rotationMatrix = QuaternionToMatrix(instanceRotation);

    // Apply rotation and scale to position
    float3 rotatedPos = mul(input.Position.xyz, rotationMatrix);
    float3 scaledPos = rotatedPos * float3(instanceScale.x, instanceScale.y, 1.0);
    float3 worldPos = scaledPos + instancePosition;

    // Apply rotation to normal
    float3 worldNormal = normalize(mul(input.Normal, rotationMatrix));

    // Apply level center offset for reflections
    float3 offsetFromCenter = worldPos - LevelCenter;
    float eyeDot = dot(offsetFromCenter, Eye);
    worldPos = worldPos + eyeDot * EyeSign;

    // Transform to projection space
    float4 projPos = mul(float4(worldPos, input.Position.w), Matrices_WorldViewProjection);

    // Apply texel offset
    output.Position.xy = projPos.xy + TexelOffset * projPos.w;
    output.Position.zw = projPos.zw;

    // Calculate texture coordinates with animation offset and repeat/clamp
    float2 texCoord = input.TexCoord;

    // Apply texture repeat/mirror flags
    float xScale = (xRepeatFlag > 0.5) ? 1.0 : -1.0;
    float yScale = (yRepeatFlag > 0.5) ? 1.0 : -1.0;
    texCoord.x *= xScale;
    texCoord.y *= yScale;

    // Apply frame scale and animation offset
    output.TexCoord.x = texCoord.x * FrameScale.x + uOffset;
    output.TexCoord.y = texCoord.y * FrameScale.y + vOffset;

    // Pass through normal
    output.Normal = worldNormal;

    // Calculate fog
    float fogDistance = projPos.w * Fog_Density;
    float fogExp = exp(fogDistance * fogDistance * fogDistance * 1.44269502); // log2(e)
    float fogAmount = 1.0 / fogExp;

    // Apply fog type modulation
    bool fogTypeZero = (Fog_Type == 0.0);
    bool fogTypeTwo = (Fog_Type == 2.0);
    fogAmount = lerp(fogAmount, 1.0, fogTypeTwo ? 1.0 : 0.0);
    fogAmount = 1.0 - fogAmount;
    fogAmount = saturate(fogAmount);

    bool ignoreFog = (IgnoreFog != 0.0);
    output.FogAmount = ignoreFog ? 0.0 : fogAmount;

    // Pass through instance filter and opacity
    output.Filter = instanceFilter;

    // Pass through flags
    output.Flags.x = fullbrightFlag;
    output.Flags.y = clampTextureFlag;

    // Pass animation data
    output.AnimData.x = vOffset;
    output.AnimData.y = FrameScale.y;

    return output;
}

// ----- Pixel Shader: Pre Pass (with lighting) -----
float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    // Calculate wrapped texture coordinate for animation
    float2 texCoord = input.TexCoord;

    // Handle texture wrapping/clamping
    if (input.Flags.y > 0.5) // ClampTexture flag
    {
        // Wrap V coordinate based on animation data
        float wrappedV = frac((texCoord.y - input.AnimData.x) / input.AnimData.y);
        texCoord.y = wrappedV * input.AnimData.y + input.AnimData.x;
    }

    // Sample texture
    float4 texColor = tex2D(AnimatedSampler, texCoord);

    // Alpha test (texkill simulation)
    float alphaTest = input.Filter.w * texColor.a - 0.00390625; // -1/256
    if (alphaTest < 0.0)
        discard;

    // Calculate lighting
    float3 lighting = float3(1.0, 1.0, 1.0);

    bool ignoreShading = (IgnoreShading != 0.0);
    if (!ignoreShading)
    {
        // Ambient lighting
        lighting = saturate(1.0 - BaseAmbient);

        // Diffuse lighting from normal
        float normalDot = saturate(dot(input.Normal, float3(1.0, 1.0, 1.0)));
        lighting += normalDot * (1.0 - DiffuseLight);

        // Add ambient contribution from normal components
        float absZ = abs(input.Normal.z);
        float3 zContrib = absZ * (1.0 - DiffuseLight);
        lighting += zContrib * 0.6;
        lighting = (input.Normal.z > -0.01) ? lighting - zContrib : lighting;

        float absX = abs(input.Normal.x);
        float3 xContrib = absX * (1.0 - DiffuseLight);
        lighting += xContrib * 0.3;
        lighting = (input.Normal.x > -0.01) ? lighting : lighting + xContrib;
        lighting = saturate(lighting);
    }

    // Apply fullbright flag
    float3 shadedColor = lighting * (1.0 - BaseAmbient) + (1.0 - DiffuseLight);
    float3 finalLighting = lerp(shadedColor, float3(1.0, 1.0, 1.0), input.Flags.x);

    // Apply fog
    finalLighting = lerp(finalLighting, 1.0, input.FogAmount);

    // Sewer hax: blend between lit color and grayscale threshold
    bool sewerHax = (SewerHax != 0.0);
    if (sewerHax)
    {
        float grayscale = (texColor.r < 0.75) ? 0.0 : 1.0;
        finalLighting = float3(grayscale, grayscale, grayscale);
    }

    // Apply to texture color
    float3 finalColor = texColor.rgb * finalLighting * 0.5;
    float finalAlpha = texColor.a * input.Filter.w;

    return float4(finalColor, finalAlpha);
}

// ----- Pixel Shader: Main Pass (simple fog blend) -----
float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    // Sample texture
    float2 texCoord = input.TexCoord;
    float4 texColor = tex2D(AnimatedSampler, texCoord);

    // Alpha test (texkill simulation)
    float alphaTest = input.Filter.w * texColor.a - 0.00390625; // -1/256
    if (alphaTest < 0.0)
        discard;

    // Apply filter color
    float3 filteredColor = texColor.rgb * input.Filter.rgb;

    // Blend with fog color
    float3 finalColor = lerp(filteredColor, Fog_Color, input.FogAmount);
    float finalAlpha = texColor.a * input.Filter.w;

    return float4(finalColor, finalAlpha);
}

// ----- Technique -----
technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS_Main();
        PixelShader = compile ps_2_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VS_Main();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
