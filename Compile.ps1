<#
.SYNOPSIS
    Compiles HLSL .fx effect files using fxc.exe (fx_2_0 profile).
#>

$ScriptRoot = $PSScriptRoot
$FxcExe = Join-Path $ScriptRoot "FXC\fxc.exe"
$EffectsDir = Join-Path $ScriptRoot "Effects"
$OutputDir = Join-Path $ScriptRoot "Out"

$shaders = @()
if ($args.Count -eq 0) {
    $shaders = Get-ChildItem -Path $EffectsDir -Filter "*.fx" | Select-Object -ExpandProperty Name
    if ($shaders.Count -eq 0) {
        Write-Host "No .fx files found in $EffectsDir" -ForegroundColor Yellow
        exit 0
    }
} else {
    foreach ($arg in $args) {
        $fullPath = Join-Path $EffectsDir $arg
        if (Test-Path $fullPath -PathType Leaf) {
            $shaders += $arg
        } else {
            Write-Warning "Shader not found, skipping: $fullPath"
        }
    }
    if ($shaders.Count -eq 0) {
        Write-Error "None of the specified shaders were found in $EffectsDir"
        exit 1
    }
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Created output directory: $OutputDir"
}

$failed = 0
foreach ($shader in $shaders) {
    $inputFile = Join-Path $EffectsDir $shader
    $outputName = [System.IO.Path]::ChangeExtension($shader, ".fxb")
    $outputFile = Join-Path $OutputDir $outputName

    Write-Host "Compiling $shader -> $outputName ..."
    $process = Start-Process -FilePath $FxcExe `
        -ArgumentList "/T fx_2_0", "/Fo `"$outputFile`"", "`"$inputFile`"" `
        -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  FAILED (exit code $($process.ExitCode))" -ForegroundColor Red
        $failed++
    }
}

if ($failed -gt 0) {
    Write-Host "`n$failed shader(s) failed to compile." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll shaders compiled successfully." -ForegroundColor Green
    exit 0
}