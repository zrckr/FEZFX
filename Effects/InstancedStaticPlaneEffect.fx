// InstancedStaticPlaneEffect.fx
// Reconstructed from bytecode assembly
// Hash: 39BAA693E665A43A94CC188B9CA4CA3DDE0EA913CAFA01392E4157B784EFAC53

// Maximum number of instances (59 instances * 4 rows per matrix = 236 registers)
#define MAX_INSTANCES 59

// Shared Parameters
float4x4 Matrices_WorldViewProjection;
float4x4 InstanceData[59];  // Row-major instanced data matrices
float2 TexelOffset;

// Fog Parameters
float Fog_Type;
float Fog_Density;
float IgnoreFog;

// Camera Parameters
float3 Eye;
float3 EyeSign;
float3 LevelCenter;

// Lighting Parameters (Pre pass)
float3 DiffuseLight;
float3 BaseAmbient;
float SewerHax;

// Fog Color (Main pass)
float3 Fog_Color;

// Texture Sampler
texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

// Vertex Shader Input
struct VertexShaderInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float InstanceId : TEXCOORD1;
};

// Vertex Shader Output (Pre Pass)
struct VertexShaderOutput_Pre
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float Fog : TEXCOORD2;
    float4 Filter : TEXCOORD3;
    float Fullbright : TEXCOORD4;
};

// Vertex Shader Output (Main Pass)
struct VertexShaderOutput_Main
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float Fog : TEXCOORD2;
    float4 Filter : TEXCOORD3;
};

// Helper function to decode flags from instance data
void DecodeFlags(float flags, out bool fullbright, out bool clampTexture, out bool xRepeat, out bool yRepeat)
{
    // Flags: Fullbright(1), ClampTexture(2), XTextureRepeat(4), YTextureRepeat(8)
    float flagValue = floor(flags);
    float4 bitTest = frac(flagValue * float4(0.5, 0.25, 0.125, 0.0625));

    // Extract individual flags
    fullbright = (bitTest.x * 2.0 - 1.0) * (bitTest.x * 2.0 - 1.0) < 0.25;
    clampTexture = bitTest.y >= 0.5;
    xRepeat = bitTest.z >= 0.5;
    yRepeat = bitTest.w >= 0.5;
}

// Helper function to apply texture repeat/clamp based on flags
float2 ApplyTextureFlags(float2 texCoord, bool xRepeat, bool yRepeat)
{
    float2 result = texCoord;

    // If repeat flag is set, wrap; otherwise clamp to [-1, 1]
    result.x = xRepeat ? result.x : lerp(result.x, -1.0, !xRepeat);
    result.y = yRepeat ? result.y : lerp(result.y, -1.0, !yRepeat);

    return result;
}

// Helper function to build rotation matrix from quaternion and apply scale
float3x3 QuaternionToMatrix(float4 q, float3 scale)
{
    // Quaternion components: q.xyz = rotation axis * sin(angle/2), q.w = cos(angle/2)
    float xx = q.x * q.x;
    float yy = q.y * q.y;
    float zz = q.z * q.z;
    float xy = q.x * q.y;
    float xz = q.x * q.z;
    float xw = q.x * q.w;
    float yz = q.y * q.z;
    float yw = q.y * q.w;
    float zw = q.z * q.w;

    // Build rotation matrix from quaternion
    float3x3 rotation;
    rotation[0] = float3(
        (1.0 - 2.0 * (yy + zz)) * scale.x,
        2.0 * (xy + zw) * scale.x,
        2.0 * (xz - yw) * scale.x
    );
    rotation[1] = float3(
        2.0 * (xy - zw) * scale.y,
        (1.0 - 2.0 * (xx + zz)) * scale.y,
        2.0 * (yz + xw) * scale.y
    );
    rotation[2] = float3(
        2.0 * (xz + yw) * scale.z,
        2.0 * (yz - xw) * scale.z,
        (1.0 - 2.0 * (xx + yy)) * scale.z
    );

    return rotation;
}

// Vertex Shader (Pre Pass)
VertexShaderOutput_Pre VertexShader_Pre(VertexShaderInput input)
{
    VertexShaderOutput_Pre output;

    // Get instance index (floor to handle negative values correctly)
    int instanceIndex = floor(abs(input.InstanceId)) * 4;

    // Extract instance data from the matrix
    // Row 0: Position.X, Position.Y, Position.Z, 0
    // Row 1: Rotation.X, Rotation.Y, Rotation.Z, Rotation.W (quaternion)
    // Row 2: Scale.X, Scale.Y, 0, Flags
    // Row 3: Filter.X, Filter.Y, Filter.Z, Opacity
    float3 position = InstanceData[instanceIndex + 0].xyz;
    float4 rotation = InstanceData[instanceIndex + 1];
    float2 scale2D = InstanceData[instanceIndex + 2].xy;
    float flags = InstanceData[instanceIndex + 2].z;
    float4 filter = InstanceData[instanceIndex + 3];

    // Decode flags
    bool fullbright, clampTexture, xRepeat, yRepeat;
    DecodeFlags(flags, fullbright, clampTexture, xRepeat, yRepeat);

    // Output fullbright flag (non-zero if fullbright)
    output.Fullbright = fullbright ? 1.0 : 0.0;

    // Apply texture coordinate flags
    output.TexCoord = ApplyTextureFlags(input.TexCoord, xRepeat, yRepeat);

    // Build rotation matrix from quaternion with scale
    float3 scale3D = float3(scale2D, scale2D.y); // Z scale = Y scale for 2D planes
    float3x3 rotationMatrix = QuaternionToMatrix(rotation, scale3D);

    // Transform vertex position
    float3 worldPos;
    worldPos.x = dot(input.Position.xyz, rotationMatrix[0]) + position.x;
    worldPos.y = dot(input.Position.xyz, rotationMatrix[1]) + position.y;
    worldPos.z = dot(input.Position.xyz, rotationMatrix[2]) + position.z;

    // Store normal (normalized rotation axis, used for lighting)
    output.Normal = rotationMatrix[2];

    // Apply billboarding effect (reflect around level center based on eye position)
    float3 centerOffset = worldPos - LevelCenter;
    float eyeDot = dot(centerOffset, Eye);
    worldPos = worldPos + eyeDot * EyeSign;

    // Transform to clip space
    float4 viewPos = float4(worldPos, input.Position.w);
    output.Position = mul(viewPos, Matrices_WorldViewProjection);

    // Apply texel offset for pixel-perfect rendering
    output.Position.xy += TexelOffset * output.Position.w;

    // Compute fog
    float fogDistance = output.Position.w;
    float fogFactor = fogDistance * Fog_Density;
    fogFactor = exp(fogFactor * fogFactor * fogFactor * 1.44269502); // log2(e)
    fogFactor = 1.0 / fogFactor;

    // Apply fog type and ignore fog settings
    bool isFogType2 = (Fog_Type - 2.0) * (Fog_Type - 2.0) < 0.0001;
    bool isFogEnabled = Fog_Type * Fog_Type < 0.0001;
    fogFactor = fogFactor * isFogType2 + isFogEnabled;
    fogFactor = -(fogFactor - 1.0);
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    output.Fog = lerp(fogFactor, -fogFactor, IgnoreFog * IgnoreFog);

    // Output filter color and opacity
    output.Filter = filter;

    return output;
}

// Vertex Shader (Main Pass)
VertexShaderOutput_Main VertexShader_Main(VertexShaderInput input)
{
    VertexShaderOutput_Main output;

    // Get instance index (floor to handle negative values correctly)
    int instanceIndex = floor(abs(input.InstanceId)) * 4;

    // Extract instance data from the matrix
    float3 position = InstanceData[instanceIndex + 0].xyz;
    float4 rotation = InstanceData[instanceIndex + 1];
    float2 scale2D = InstanceData[instanceIndex + 2].xy;
    float flags = InstanceData[instanceIndex + 2].z;
    float4 filter = InstanceData[instanceIndex + 3];

    // Decode flags
    bool fullbright, clampTexture, xRepeat, yRepeat;
    DecodeFlags(flags, fullbright, clampTexture, xRepeat, yRepeat);

    // Apply texture coordinate flags
    output.TexCoord = ApplyTextureFlags(input.TexCoord, xRepeat, yRepeat);

    // Build rotation matrix from quaternion with scale
    float3 scale3D = float3(scale2D, scale2D.y);
    float3x3 rotationMatrix = QuaternionToMatrix(rotation, scale3D);

    // Transform vertex position
    float3 worldPos;
    worldPos.x = dot(input.Position.xyz, rotationMatrix[0]) + position.x;
    worldPos.y = dot(input.Position.xyz, rotationMatrix[1]) + position.y;
    worldPos.z = dot(input.Position.xyz, rotationMatrix[2]) + position.z;

    // Apply billboarding effect
    float3 centerOffset = worldPos - LevelCenter;
    float eyeDot = dot(centerOffset, Eye);
    worldPos = worldPos + eyeDot * EyeSign;

    // Transform to clip space
    float4 viewPos = float4(worldPos, input.Position.w);
    output.Position = mul(viewPos, Matrices_WorldViewProjection);

    // Apply texel offset
    output.Position.xy += TexelOffset * output.Position.w;

    // Compute fog
    float fogDistance = output.Position.w;
    float fogFactor = fogDistance * Fog_Density;
    fogFactor = exp(fogFactor * fogFactor * fogFactor * 1.44269502);
    fogFactor = 1.0 / fogFactor;

    bool isFogType2 = (Fog_Type - 2.0) * (Fog_Type - 2.0) < 0.0001;
    bool isFogEnabled = Fog_Type * Fog_Type < 0.0001;
    fogFactor = fogFactor * isFogType2 + isFogEnabled;
    fogFactor = -(fogFactor - 1.0);
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    output.Fog = lerp(fogFactor, -fogFactor, IgnoreFog * IgnoreFog);

    // Output filter color and opacity
    output.Filter = filter;

    return output;
}

// Pixel Shader (Pre Pass - with lighting)
float4 PixelShader_Pre(VertexShaderOutput_Pre input) : COLOR0
{
    // Sample base texture
    float4 color = tex2D(BaseSampler, input.TexCoord);

    // Alpha test (discard if opacity makes alpha < -1/256)
    clip(input.Filter.w * color.a - 1.0/256.0);

    // Compute lighting based on normal
    float3 lighting;

    // Saturate ambient and fullbright
    float3 ambientFull = saturate(input.Fullbright + (1.0 - BaseAmbient));

    // Dot product for normal-based lighting
    float normalDot = saturate(dot(input.Normal, 1.0));

    // Base lighting
    lighting = normalDot * (1.0 - DiffuseLight) + ambientFull;

    // Add contribution from abs(normal.z) - top/bottom lighting
    float absZ = abs(input.Normal.z);
    lighting += absZ * (1.0 - DiffuseLight) * 0.6;

    // Conditional blend based on normal.z sign
    float3 litNoZ = ambientFull + normalDot * (1.0 - DiffuseLight);
    lighting = (input.Normal.z + 0.01 < 0.0) ? litNoZ : lighting;

    // Add contribution from abs(normal.x) - side lighting
    float absX = abs(input.Normal.x);
    lighting += absX * (1.0 - DiffuseLight) * 0.3;

    // Conditional blend based on normal.x sign
    lighting = saturate((input.Normal.x + 0.01 < 0.0) ? litNoZ : lighting);

    // Apply fullbright override (multiply by inverted diffuse light)
    float3 fullbrightMod = input.Fullbright * (1.0 - DiffuseLight);

    // Final lighting
    lighting = lighting * DiffuseLight + fullbrightMod;

    // Apply fog
    lighting = lerp(1.0, lighting, input.Fog);

    // SewerHax effect - desaturate based on texture luminance
    // If texture.r < 0.75, desaturate to grayscale
    float3 grayscale = (color.r < 0.75) ? 0.5 : 1.0;
    lighting = lerp(lighting, grayscale, SewerHax * SewerHax);

    // Apply filter color and lighting
    color.rgb = color.rgb * lighting * 0.5;
    color.a *= input.Filter.w;

    return color;
}

// Pixel Shader (Main Pass - simple)
float4 PixelShader_Main(VertexShaderOutput_Main input) : COLOR0
{
    // Sample base texture
    float4 color = tex2D(BaseSampler, input.TexCoord);

    // Alpha test
    clip(input.Filter.w * color.a - 1.0/256.0);

    // Apply filter color
    float3 filteredColor = color.rgb * input.Filter.rgb;

    // Apply fog (lerp to fog color based on fog factor)
    color.rgb = lerp(filteredColor, Fog_Color, input.Fog);
    color.a *= input.Filter.w;

    return color;
}

// Technique
technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VertexShader_Pre();
        PixelShader = compile ps_2_0 PixelShader_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VertexShader_Main();
        PixelShader = compile ps_2_0 PixelShader_Main();
    }
}
