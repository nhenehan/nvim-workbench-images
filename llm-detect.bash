#!/usr/bin/env bash
# Detect the best llama.cpp device in this container and print it as shell assignments:
#
#   LLM_BACKEND   cuda | rocm | vulkan | cpu
#   LLM_DEVICE    llama.cpp device name (CUDA0, ROCm0, Vulkan0) or "none"
#   LLM_MEM_MB    memory budget for weights + KV cache on that device
#   LLM_THREADS   physical CPU cores
#   LLM_GPU_NAME  human-readable device description
#   LLM_UMA       1 when the GPU shares system RAM (APU / iGPU)
#   HSA_OVERRIDE_GFX_VERSION  only for ROCm on GPUs rocBLAS ships no kernels for
#
# Usage: source <(llm-detect.bash)      Override with LLM_BACKEND=cuda|rocm|vulkan|cpu.
#
# The device list comes from `llama-server --list-devices`, i.e. what this build
# can actually drive with the devices passed into the container -- not from lspci.
set -uo pipefail

LLAMA_BIN="${LLAMA_BIN:-$HOME/opt/llama.cpp/build/bin}"
SYSFS="${LLM_SYSFS:-/sys}" # overridable for testing

mem_kb() { awk -v k="$1:" '$1 == k { print $2 }' /proc/meminfo; }
MEM_TOTAL_MB=$(($(mem_kb MemTotal) / 1024))
MEM_AVAIL_MB=$(($(mem_kb MemAvailable) / 1024))

THREADS=$(lscpu -p=CORE,SOCKET 2>/dev/null | grep -v '^#' | sort -u | wc -l)
[ "${THREADS:-0}" -gt 0 ] || THREADS=$(nproc)

# "Vulkan0|AMD Radeon 780M Graphics (RADV PHOENIX)|16384|15002" per device.
declare -a DEVICES=()
if [ -x "$LLAMA_BIN/llama-server" ]; then
    listing=$("$LLAMA_BIN/llama-server" --list-devices 2>&1 || true)
    while IFS= read -r line; do
        DEVICES+=("$line")
    done < <(sed -nE 's/^ +([A-Za-z]+[0-9]+): (.*) \(([0-9]+) MiB, ([0-9]+) MiB free\)$/\1|\2|\3|\4/p' <<<"$listing")
fi

# Shared-memory GPU (APU / iGPU)? Vulkan's device type covers every vendor; KFD
# reports no local memory for AMD APUs when Vulkan tooling is unavailable.
UMA_GPU=0
if vulkaninfo --summary 2>/dev/null | grep -q 'PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU'; then
    UMA_GPU=1
elif awk '$1 == "gfx_target_version" { g[FILENAME] = $2 }
          $1 == "local_mem_size" { m[FILENAME] = $2 }
          END { for (f in g) if (g[f] != 0 && m[f] == 0) exit 0; exit 1 }' \
    ${SYSFS}/class/kfd/kfd/topology/nodes/*/properties 2>/dev/null; then
    UMA_GPU=1
fi

find_device() { # prefix -> first matching "name|desc|total|free"
    local d
    for d in "${DEVICES[@]+"${DEVICES[@]}"}"; do
        [[ $d == "$1"* ]] && { echo "$d"; return 0; }
    done
    return 1
}

# gfx id of the first KFD GPU node, e.g. 110003 -> gfx1103.
amd_gfx() {
    local v
    v=$(grep -h gfx_target_version ${SYSFS}/class/kfd/kfd/topology/nodes/*/properties 2>/dev/null |
        awk '$2 != 0 { print $2; exit }')
    [ -n "$v" ] && printf 'gfx%d%x%x\n' $((v / 10000)) $((v / 100 % 100)) $((v % 100))
}

pick() { # backend -> sets BACKEND/DEVICE/... from the device list
    local prefix dev
    case "$1" in
        cuda) prefix=CUDA ;;
        rocm) prefix=ROCm ;;
        vulkan) prefix=Vulkan ;;
        *) return 1 ;;
    esac
    dev=$(find_device "$prefix") || return 1
    IFS='|' read -r DEVICE GPU_NAME _total MEM_MB <<<"$dev"
    BACKEND=$1
}

BACKEND=cpu DEVICE=none GPU_NAME="CPU ($THREADS cores)" MEM_MB=0 UMA=0

case "${LLM_BACKEND:-auto}" in
    auto)
        # NVIDIA: CUDA. AMD dGPU: ROCm. AMD APU / Intel / anything else: Vulkan --
        # on RDNA3 iGPUs Vulkan is faster than ROCm and needs no gfx override.
        pick cuda ||
            { [ "$UMA_GPU" = 0 ] && pick rocm; } ||
            pick vulkan ||
            pick rocm ||
            true
        ;;
    cpu) ;;
    *)
        pick "$LLM_BACKEND" || echo "llm-detect: no ${LLM_BACKEND} device visible, falling back to CPU" >&2
        ;;
esac

[ "$BACKEND" != cpu ] && UMA=$UMA_GPU
if [ "$BACKEND" = rocm ] && [ -z "${HSA_OVERRIDE_GFX_VERSION:-}" ]; then
    # Older ROCm reports only an APU's BIOS carve-out; the usable pool is GTT.
    if [ "$UMA" = 1 ] && [ "${MEM_MB:-0}" -le 4096 ]; then
        gtt=$(cat ${SYSFS}/class/drm/card*/device/mem_info_gtt_total 2>/dev/null | sort -n | tail -1)
        [ -n "$gtt" ] && MEM_MB=$((gtt / 1024 / 1024))
    fi
    case "$(amd_gfx)" in
        gfx1103) HSA_OVERRIDE_GFX_VERSION=11.0.0 ;; # Radeon 780M/760M
        gfx1035 | gfx1036) HSA_OVERRIDE_GFX_VERSION=10.3.0 ;;
    esac
fi

if [ "$BACKEND" = cpu ]; then
    MEM_MB=$((MEM_AVAIL_MB * 70 / 100))
elif [ "$UMA" = 1 ]; then
    # The GPU heap is carved out of system RAM; leave the rest of the box usable.
    cap=$((MEM_TOTAL_MB * 60 / 100))
    [ "$MEM_MB" -gt "$cap" ] && MEM_MB=$cap
fi

printf 'LLM_BACKEND=%q\n' "$BACKEND"
printf 'LLM_DEVICE=%q\n' "$DEVICE"
printf 'LLM_MEM_MB=%q\n' "$MEM_MB"
printf 'LLM_THREADS=%q\n' "$THREADS"
printf 'LLM_GPU_NAME=%q\n' "$GPU_NAME"
printf 'LLM_UMA=%q\n' "$UMA"
[ -n "${HSA_OVERRIDE_GFX_VERSION:-}" ] && printf 'export HSA_OVERRIDE_GFX_VERSION=%q\n' "$HSA_OVERRIDE_GFX_VERSION"
exit 0
