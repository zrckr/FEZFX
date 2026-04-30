#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FXC_EXE="$SCRIPT_DIR/FXC/fxc.exe"
EFFECTS_DIR="$SCRIPT_DIR/Effects"
OUTPUT_DIR="$SCRIPT_DIR/Out"

if ! command -v wine &> /dev/null; then
    echo "ERROR: Wine is not installed or not in PATH. Please install it." >&2
    exit 1
fi

shaders=()
if [ $# -eq 0 ]; then
    shopt -s nullglob
    for file in "$EFFECTS_DIR"/*.fx; do
        shaders+=("$(basename "$file")")
    done
    if [ ${#shaders[@]} -eq 0 ]; then
        echo "No .fx files found in $EFFECTS_DIR"
        exit 0
    fi
else
    for arg in "$@"; do
        full_path="$EFFECTS_DIR/$arg"
        if [ -f "$full_path" ]; then
            shaders+=("$arg")
        else
            echo "WARNING: Shader not found, skipping: $full_path" >&2
        fi
    done
    if [ ${#shaders[@]} -eq 0 ]; then
        echo "ERROR: None of the specified shaders were found in $EFFECTS_DIR" >&2
        exit 1
    fi
fi

mkdir -p "$OUTPUT_DIR"

failed=0
for shader in "${shaders[@]}"; do
    output_name="${shader%.fx}.fxb"
    echo "Compiling $shader -> $output_name ..."

    # Switch to Effects directory for the compilation step
    pushd "$EFFECTS_DIR" > /dev/null

    # fxc.exe is called with its absolute path; source and output are relative
    if wine "$FXC_EXE" /T fx_2_0 /Fo "$output_name" "$shader"; then
        echo "  OK"
        # Move the compiled file to the Out folder and clean up Effects
        cp "$output_name" "$OUTPUT_DIR/"
        rm -f "$output_name"
    else
        echo "  FAILED"
        failed=$((failed + 1))
        # Remove any partial output
        rm -f "$output_name"
    fi

    popd > /dev/null
done

if [ $failed -gt 0 ]; then
    echo ""
    echo "$failed shader(s) failed to compile." >&2
    exit 1
else
    echo ""
    echo "All shaders compiled successfully."
    exit 0
fi