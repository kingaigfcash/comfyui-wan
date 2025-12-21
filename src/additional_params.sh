#!/bin/bash
# Upload this file to /workspace/additional_params.sh on RunPod
# It will run before the main start.sh script

echo "=========================================="
echo "Running additional_params.sh test script"
echo "=========================================="

# Step 1: Install minimal CPU PyTorch first for reliable GPU detection
echo "Installing minimal PyTorch for GPU detection..."
pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu -q 2>/dev/null || true

# Step 2: Detect GPU compute capability using nvidia-smi as primary method
echo "Detecting GPU architecture..."
GPU_ARCH=0

# Try nvidia-smi first (more reliable, doesn't need PyTorch CUDA)
if command -v nvidia-smi > /dev/null 2>&1; then
    # Get compute capability from nvidia-smi
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
    echo "Detected GPU: $GPU_NAME"
    
    # Map GPU names to compute capabilities
    case "$GPU_NAME" in
        *"5090"*|*"5080"*|*"5070"*|*"Blackwell"*|*"PRO 6000"*"Blackwell"*)
            GPU_ARCH=120
            ;;
        *"4090"*|*"4080"*|*"4070"*|*"L40"*|*"RTX 6000"*"Ada"*|*"Ada"*)
            GPU_ARCH=89
            ;;
        *"H100"*|*"H200"*)
            GPU_ARCH=90
            ;;
        *"A100"*|*"A10"*|*"3090"*|*"3080"*|*"3070"*)
            GPU_ARCH=80
            ;;
        *)
            # Fallback to PyTorch detection
            GPU_ARCH=$(python3 -c "import torch; print(torch.cuda.get_device_capability()[0] * 10 + torch.cuda.get_device_capability()[1])" 2>/dev/null || echo "0")
            ;;
    esac
fi

# If still 0, try PyTorch detection as fallback
if [ "$GPU_ARCH" -eq 0 ]; then
    GPU_ARCH=$(python3 -c "import torch; print(torch.cuda.get_device_capability()[0] * 10 + torch.cuda.get_device_capability()[1])" 2>/dev/null || echo "0")
fi

echo "Detected GPU compute capability: SM $GPU_ARCH"

# Step 3: Install appropriate PyTorch version
# Use cu128 nightly for all modern GPUs (SM 80+) for best compatibility and performance
if [ "$GPU_ARCH" -ge 120 ]; then
    # Blackwell (RTX 5090, RTX PRO 6000 Blackwell) - SM 12.0+
    echo "Blackwell GPU detected (SM 120+). Installing PyTorch nightly with CUDA 12.8..."
    pip install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
elif [ "$GPU_ARCH" -ge 80 ]; then
    # Ada (SM 89), Hopper (SM 90), Ampere (SM 80) - all use cu128 for best compatibility
    echo "Modern GPU detected (SM 80+). Installing PyTorch nightly with CUDA 12.8..."
    pip install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
else
    # Fallback for older or undetected GPUs - use stable cu124
    echo "Older/undetected GPU. Using stable PyTorch with CUDA 12.4..."
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
fi

# Install missing dependencies
echo "Installing additional dependencies..."
pip install --no-cache-dir lpips groundingdino-py imageio-ffmpeg

# Install exiftool
if ! which exiftool > /dev/null 2>&1; then
    echo "Installing exiftool..."
    apt-get update && apt-get install -y libimage-exiftool-perl
fi

# Step 4: Verify PyTorch installation and architecture support
echo "=========================================="
echo "PyTorch installation verification:"
python3 -c "import torch; print(f'PyTorch {torch.__version__} | CUDA {torch.version.cuda} | GPU: {torch.cuda.get_device_name(0)}')"
echo ""
echo "Supported CUDA architectures:"
python3 -c "import torch; print(torch.cuda.get_arch_list())"
echo "=========================================="

echo "additional_params.sh completed!"
