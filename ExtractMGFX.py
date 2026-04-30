#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.10"
# dependencies = ["jinja2"]
# ///

import re
import sys
from datetime import datetime, timezone
from itertools import groupby
from jinja2 import Template
from pathlib import Path

KNOWN_INPUTS = {
    "AcceptColor": "float3",
    "ActualOpacity": "float",
    "Additive": "bool",
    "AlphaIsEmissive": "bool",
    "AnimatedTexture": "texture",
    "AspectRatio": "float",
    "AtlasTexture": "texture",
    "Background": "float",
    "BaseAmbient": "float3",
    "BaseTexture": "texture",
    "Billboard": "bool",
    "BlackSwap": "float3",
    "Blink": "bool",
    "BlurWidth": "float",
    "Brightness": "float",
    "CameraRotation": "float4x4",
    "ColorSwap": "bool",
    "Complete": "bool",
    "CubemapTexture": "texture",
    "CubeOffset": "float3",
    "DawnContribution": "float",
    "DiffuseLight": "float3",
    "Direction": "float2",
    "DistanceFactor": "float",
    "DuskContribution": "float",
    "EightShapeStep": "float",
    "Emissive": "float",
    "Eye": "float3",
    "EyeSign": "float3",
    "Fog_Color": "float3",
    "Fog_Density": "float",
    "Fog_Type": "int",
    "FogDensity": "float",
    "ForceShading": "bool",
    "FrameScale": "float2",
    "Fullbright": "bool",
    "GlitchTexture": "texture",
    "GraySwap": "float3",
    "HueOffset": "float",
    "IgnoreFog": "bool",
    "IgnoreShading": "bool",
    "ImmobilityFactor": "float",
    "InstanceData": "float4x4 %s[8]",
    "IsEmerged": "bool",
    "IsTextureEnabled": "bool",
    "IsWobbling": "bool",
    "LeftFilter": "float4x4",
    "LeftTexture": "texture",
    "LevelCenter": "float3",
    "MainBufferTexture": "texture",
    "Material_Diffuse": "float3",
    "Material_Opacity": "float",
    "Matrices_Texture": "float3x3",
    "Matrices_ViewProjection": "float4x4",
    "Matrices_World": "float4x4",
    "Matrices_WorldInverseTranspose": "float4x4",
    "Matrices_WorldViewProjection": "float4x4",
    "MaxHeight": "float",
    "NewFrameTexture": "texture",
    "NextFrameData": "float4x4",
    "NightContribution": "float",
    "NoMoreFez": "bool",
    "NoTexture": "bool",
    "Offset": "float",
    "OldFrameTexture": "texture",
    "PixelsPerTrixel": "float",
    "PseudoWorldMatrix": "float4x4",
    "RandomSeed": "float3",
    "RedGamma": "float",
    "RedSwap": "float3",
    "Right": "float3",
    "RightFilter": "float4x4",
    "RightTexture": "texture",
    "Saturation": "float",
    "ScreenCenterSide": "float",
    "SewerHax": "bool",
    "ShadowPass": "bool",
    "Shiny": "bool",
    "ShoreTotalWidth": "float",
    "Silhouette": "bool",
    "SinceStarted": "float",
    "SpecularEnabled": "bool",
    "TexelOffset": "float2",
    "TexelSize": "float2",
    "TextureEnabled": "bool",
    "TextureSize": "float2",
    "Theta": "float",
    "TiltTwoAxis": "bool",
    "Time": "float",
    "TimeAccumulator": "float",
    "TimeStep": "float",
    "Timing": "float",
    "Unstable": "bool",
    "VaryingOpacity": "float",
    "ViewportSize": "float2",
    "ViewScale": "float",
    "WhiteSwap": "float3",
    "YellowSwap": "float3",
    "Weights": "float %s[5]",
    "Offsets": "float %s[5]",
    "Intensity": "float2",
}

SPECIAL_INPUTS = {
    "TrileEffect": {
        "InstanceData": "float4 %s[32]",
    },
    "InstancedDotEffect": {
        "InstanceData": "float4 %s[32]",
    },
    "VibratingEffect": {
        "Intensity": "float",
    },
}

FX_TEMPLATE = Template("""// Name: {{ name }}
// Timestamp: {{ timestamp }}

{% for input in inputs %}{{ input.type }} {{ input.name }};
{% endfor %}
{% for sampler in samplers %}sampler2D {{ sampler.name }} = sampler_state
{
    Texture = <{{ sampler.input }}>;
};{% if not loop.last %}

{% endif %}{% endfor %}

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

{% if vertex %}VS_OUTPUT VS(VS_INPUT input)
{
/*
{{ vertex.code }}
*/
    VS_OUTPUT output;
    return output;
}{% endif %}

{% for pass in passes %}float4 PS_{{ pass.name }}(VS_OUTPUT input) : COLOR0
{
/*
{{ pass.code }}
*/
    return input.Color;
}{% if not loop.last %}

{% endif %}{% endfor %}

technique {{ technique }}
{
    {% for pass in passes %}pass {{ pass.name }}
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_{{ pass.name }}();
    }{% if not loop.last %}

    {% endif %}{% endfor %}
}
""")


def extract_data(content: str):
    shader_pattern = r"(#ifdef GL_ES.*?^}\s*$)"
    shaders = re.findall(shader_pattern, content, re.MULTILINE | re.DOTALL)
    shaders[0], shaders[1] = shaders[1], shaders[0]  # Make vertex shader first

    last_shader_end = content.rfind("}")
    metadata = content[last_shader_end:].strip()
    metadata = re.findall(r"\b([A-Z][a-zA-Z0-9_]*)\b", metadata)

    return shaders, metadata


def split_metadata(metadata):
    technique = ""
    for name in ["TSM2", "ShaderModel2"]:
        if name in metadata:
            technique = name
            break
    assert technique

    chunks = []
    for k, g in groupby(metadata, lambda x: x == technique):
        if not k:
            chunks.append(list(g))

    return chunks, technique


def find_inputs(input_names, stem):
    special_inputs = SPECIAL_INPUTS.get(stem, {})
    inputs = []
    for input in input_names:
        assert input in KNOWN_INPUTS
        input_type = KNOWN_INPUTS[input]

        if input in special_inputs:
            input_type = special_inputs[input]

        if "%s" in input_type:
            formatted: str = input_type % input
            input_type, input = formatted.split(" ")

        inputs.append(
            {
                "type": input_type,
                "name": input,
            }
        )

    return inputs


def find_fragment_passes(pass_names, shaders):
    passes = []
    for i, pass_ in enumerate(pass_names):
        passes.append({"name": pass_, "code": shaders[i]})

    return passes


def find_samplers(input_names):
    samplers = []
    for texture in input_names:
        if texture.endswith("Texture") and texture != "Matrices_Texture":
            name = texture.replace("Texture", "Sampler")
            samplers.append(
                {
                    "name": name,
                    "input": texture,
                }
            )

    return samplers


def find_vertex(shaders):
    assert len(shaders) > 0
    return {"code": shaders[0]}


def main():
    if len(sys.argv) < 2:
        print("Usage: python Extract.py <input_fxb_file> [output_fx_file]")
        print(
            "If output_fx_file is not specified, it will be generated with the same name as input but .fx extension"
        )
        sys.exit(1)

    input_fxb = Path(sys.argv[1])
    if not input_fxb.exists():
        print(f"Error: Input file '{input_fxb}' does not exist")
        sys.exit(1)

    if input_fxb.suffix.lower() != ".fxb":
        print(f"Warning: Input file '{input_fxb}' does not have .fxb extension")

    if len(sys.argv) >= 3:
        output_fx = Path(sys.argv[2])
    else:
        output_fx = input_fxb.with_suffix(".fx")

    with open(input_fxb, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    shaders, metadata = extract_data(content)
    chunks, technique = split_metadata(metadata)
    inputs = find_inputs(chunks[0], input_fxb.stem)
    samplers = find_samplers(chunks[0])
    vertex = find_vertex(shaders[:1])
    passes = find_fragment_passes(chunks[1], shaders[1:])

    timestamp = (
        datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    )

    fx = FX_TEMPLATE.render(
        name=input_fxb.stem,
        timestamp=timestamp,
        inputs=inputs,
        samplers=samplers,
        vertex=vertex,
        passes=passes,
        technique=technique,
    )

    print(f"Extracted: {input_fxb} -> {output_fx}")

    output_fx.parent.mkdir(parents=True, exist_ok=True)
    with open(output_fx, "wt", encoding="utf-8", errors="ignore") as f:
        f.write(fx)


if __name__ == "__main__":
    main()
