// DotEffect
// 735B2C5FDECA1A372AABF1690291B8F916EF26D55851D42A998040CF7E98169B

float Material_Opacity;
float4x4 Matrices_WorldViewProjection;
float2 TexelOffset;
float3 Material_Diffuse;
float HueOffset;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;  // HSV color: x - Hue, y - Saturation, z - Value
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : TEXCOORD0;
};

float3 HSVtoRGB(float hue, float saturation, float value)
{
    // Scale hue to [0, 6) range to determine which of 6 color sectors
    float hue6 = hue * 6.0;   
    float sector = floor(hue6);                          
    float f = hue6 - sector;
    float p = value * (1.0 - saturation);               
    float q = value * (1.0 - saturation * f);           
    float t = value * (1.0 - saturation * (1.0 - f));   

    // Calculate selector values
    float divisor = step(1.0, sector) * 12.0 - 6.0;
    float selectorFrac = frac(sector / divisor) * divisor;
    float selectorFloor = floor(selectorFrac);

    // Determine final selector value
    float isNegative = step(selectorFrac, -selectorFrac);
    float fracIsPositive = step(frac(selectorFrac), -frac(selectorFrac));
    float selectorValue = isNegative * fracIsPositive + selectorFloor;

    // Create selector masks for each sector
    float4 offsets = selectorValue - float4(1, 2, 3, 4);
    float4 selectors = step(offsets, -offsets);
    float selectorBase = step(selectorValue, -selectorValue);
    
    // Build the 6 possible RGB combinations
    float4 components = float4(q, value, p, t);

    // Use cascading lerps to select the correct RGB based on sector
    float3 color;
    color.xz = lerp(components.yx, float2(t, value), selectors.w);
    color.y = p;
    color = lerp(color, components.zxy, selectors.z);
    color = lerp(color, components.zyw, selectors.y);
    color = lerp(color, components.xyz, selectors.x);
    color = lerp(color, components.ywz, selectorBase);

    return color;
}

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldViewPos.w) + worldViewPos.xy;
    output.Position.zw = worldViewPos.zw;
    
    float hue = input.Color.x + HueOffset;
    float saturation = input.Color.y;
    float value = input.Color.z;
    
    float3 color = HSVtoRGB(hue, saturation, value);
    output.Color.rgb = color * Material_Diffuse * 0.35;
    output.Color.a = Material_Opacity;
    
    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    return input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }
}