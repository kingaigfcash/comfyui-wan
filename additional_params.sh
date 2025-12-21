#!/bin/bash
# Upload this file to /workspace/additional_params.sh on RunPod
# It will run before the main start.sh script

echo "=========================================="
echo "Running additional_params.sh test script"
echo "=========================================="

# Detect GPU compute capability
echo "Detecting GPU architecture..."
GPU_ARCH=$(python3 -c "import torch; print(torch.cuda.get_device_capability()[0] * 10 + torch.cuda.get_device_capability()[1])" 2>/dev/null || echo "0")
echo "Detected GPU compute capability: SM $GPU_ARCH"

if [ "$GPU_ARCH" -ge 120 ]; then
    # Blackwell (RTX 5090, RTX 6000 Blackwell) - SM 12.0+
    echo "Blackwell GPU detected (SM 120+). Installing PyTorch nightly with CUDA 12.8..."
    pip install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
elif [ "$GPU_ARCH" -ge 89 ]; then
    # Ada Lovelace (RTX 4090, L40S, RTX 6000 Ada) - SM 8.9
    # Hopper (H100) - SM 9.0
    echo "Ada/Hopper GPU detected (SM 89-90). Using stable PyTorch with CUDA 12.4..."
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
elif [ "$GPU_ARCH" -ge 80 ]; then
    # Ampere (A100, RTX 3090) - SM 8.0
    echo "Ampere GPU detected (SM 80+). Using stable PyTorch with CUDA 12.4..."
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
else
    # Fallback for older or undetected GPUs
    echo "GPU architecture not detected or older GPU. Using stable PyTorch with CUDA 12.4..."
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

# Verify PyTorch
echo "=========================================="
echo "PyTorch installation verification:"
python3 -c "import torch; print(f'PyTorch {torch.__version__} | CUDA {torch.version.cuda} | GPU: {torch.cuda.get_device_name(0)}')"
echo "=========================================="

echo "additional_params.sh completed!"
