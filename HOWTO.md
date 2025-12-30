# How to reconstruct a shader?

## 0. History

The game was originally released on Xbox 360 (which uses its own version of
DirectX), and shortly after, the game was ported to PC for Windows, Linux, and
MacOS.

For cross-platform compatibility firstly the game was migrated from XNA
Framework to the then-current (2013) version of MonoGame Framework, which runs
on OpenGL. To make the shaders work in MonoGame, shaders were converted using
the [MonoGame Effects
Compiler](https://docs.monogame.net/articles/getting_started/tools/mgfxc.html)
from the original HLSL code into an MGFX container file, which contains
generated GLSL code and metadata.

In 2016, the game was re-ported to FNA, a fully compatible reimplementation of
XNA 4.0 Refresh. FNA integrates the
[MojoShader](https://github.com/icculus/mojoshader) library, which allows
generating GLSL code on the fly from HLSL bytecode. The compiled `.fxc` files
were added in version `1.12`.

As a result, there are three ways to recreate the shader:

## 1. DirectX Effects

When you install the latest Windows Kit, it comes with the `fxc` compiler. It
allows you to compile shaders in the `fx_2_0` profile. However, in this version
of the compiler, this profile has been declared obsolete, and the ability to
obtain assembly code for this profile using the `/dumpbin` command has been
removed.

This can be solved by using an older version of `fxc` with full support for
`fx_2_0`, for example from the [Microsoft DirectX SDK June
2010](https://archive.org/details/dxsdk_jun10).

To decompile the shader:

```cmd
fxc.exe /dumpbin /T fx_2_0 FastBlurEffect.fxc /Fc FastBlurEffect.asm
```

After that, we get a text file with the following contents:
* List of passes
* Vertex assembly
* Fragment assembly
* A list of uniforms and their types for each assembly
* List of attributes
* Version of Shader Model

Keep in mind:
* The sampler is configured on the XNA side.
* The compiler unrolls `for` loops.
* If the shader has multiple fragment passes, then the single vertex shader will
  be compiled for each pass.
* The compiler performs code optimization.

## 2. MonoGame Effects

Alongside the `.fxc` files there are also `.fxb` files, which are the old
pre-FNA shaders in MGFX format.

Use the `extract_mgfx.py` with `uv` for extracting data from MGFX files:

```bash
./extract_mgfx.py FastBlurEffect.fxb FastBlurEffect.fx
```

> [!NOTE]
> This script only extracts the GLSL code, it does not reconstruct it!

Commented code inside functions is the transfer of HLSL bytecode to GLSL.
At the same time, the approximate structure of the FX shader is restored,
namely: the order of uniforms, samplers, and passes.

> [!WARNING]
> While most of the code is more or less the same as `.fxc`, some of the shaders
> were fixed or updated when switching to FNA. As a result, the final GLSL code
> will differ from the GLSL code from MGFX!

Keep in mind:
* The `vec4` type is used for uniforms.
* Calculations in the preshader are performed on the game side (more precisely,
  on the `MonoGame` or `MojoShader` side), rather than within GLSL.
* HLSL uses the DirectX matrix format (row-major), while GLSL uses the OpenGL
  format (column-major).
* In GLSL code, coordinate systems are additionally converted (from left-handed
  to right-handed).

## 3. Graphics Analyzer

> [!WARNING]
> This is a method for those who have **a LOT of free time**.
> 
> Consider use one of two previous methods.

Since the game runs via OpenGL, we can intercept the shader code using a
graphics analyzer:
* [Nvidia Nsight Graphics](https://developer.nvidia.com/nsight-graphics)
* [Intel Graphics Performance
  Analyzers](https://www.intel.com/content/www/us/en/developer/tools/graphics-performance-analyzers/download.html)
  (will be used further as an example)
* Whatever AMD uses for OpenGL debugging...

> [!NOTE] 
> **What about RenderDoc?**
> 
> When attempting to use RenderDoc with `FNA_OPENGL_FORCE_CORE_PROFILE=1` envvar
> on the FNA version, the game does not display most of the graphics and tends
> to crash: ![](Docs/CoreProfileIssue.png)

Steps to obtain the shader code on Intel GPA:

1. Launch the game via Intel GPA and capture the frame you are interested in.
   ![](Docs/IntelGPA1.png)
2. Open the saved frame using the `Graphics Frame Analyzer` tool.
   ![](Docs/IntelGPA2.png)
3. Select the pixel that the shader passed over and open the step you are
   interested in via `Pixel History`, along with the shader code in it.
   ![](Docs/IntelGPA3.png)
4. Repeat steps 1-3.
5. ...
6. PROFIT! You got all shaders... (or not 🌚).
  
Joking aside, this method is not so much about obtaining the code as it is about
verifying the accuracy of MojoShader's GLSL code generation of reconstructed
version of a shader (although `fxc /dumpbin` handles this case just fine as
well, but for HLSL bytecode).
