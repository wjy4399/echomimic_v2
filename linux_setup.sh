#!/bin/bash

# Set environment variables
FFMPEG_PATH="/path/to/ffmpeg-4.4-amd64-static"

# Function for checking command success
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error during $1. Exiting."
        exit 1
    fi
}

# Check if directory exists and clone if it doesn't
if [ ! -d "echomimic_v2" ]; then
    echo "Cloning echomimic_v2 repository..."
    git clone https://github.com/antgroup/echomimic_v2
    check_command "git clone echomimic_v2"
else
    echo "echomimic_v2 directory already exists. Skipping clone."
fi

cd echomimic_v2

# Upgrade pip if necessary
echo "Upgrading pip..."
pip install --upgrade pip
check_command "pip upgrade"

# Check if core dependencies are installed and install if not
if ! pip show torch &>/dev/null; then
    echo "Installing torch dependencies..."
    pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 xformers==0.0.28.post3 --index-url https://download.pytorch.org/whl/cu124
    check_command "torch dependencies installation"
else
    echo "Torch dependencies already installed. Skipping installation."
fi

if ! pip show torchao &>/dev/null; then
    pip install torchao --index-url https://download.pytorch.org/whl/nightly/cu124
    check_command "torchao installation"
else
    echo "torchao already installed. Skipping installation."
fi

if ! pip show facenet_pytorch &>/dev/null; then
    pip install --no-deps facenet_pytorch==2.6.0
    check_command "facenet_pytorch installation"
else
    echo "facenet_pytorch already installed. Skipping installation."
fi

# Install ffmpeg if it's not already installed
if ! command -v ffmpeg &>/dev/null; then
    echo "Downloading and installing FFmpeg..."
    wget https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.4-amd64-static.tar.xz
    check_command "ffmpeg download"

    tar -xvf ffmpeg-4.4-amd64-static.tar.xz
    check_command "ffmpeg extraction"

    export FFMPEG_PATH="$PWD/ffmpeg-4.4-amd64-static"
    echo "FFmpeg installed at $FFMPEG_PATH"
else
    echo "FFmpeg is already installed. Skipping installation."
fi

# Initialize Git LFS and clone pretrained weights if not already present
if [ ! -d "pretrained_weights" ]; then
    echo "Setting up Git LFS and cloning pretrained weights..."
    git lfs install
    check_command "git lfs install"

    git clone https://huggingface.co/BadToBest/EchoMimicV2 pretrained_weights
    check_command "clone pretrained_weights"

    cd pretrained_weights

    git clone https://huggingface.co/stabilityai/sd-vae-ft-mse
    check_command "clone sd-vae-ft-mse"

    git clone https://huggingface.co/lambdalabs/sd-image-variations-diffusers
    check_command "clone sd-image-variations-diffusers"
else
    echo "Pretrained weights already cloned. Skipping."
fi

# Set up audio processor and download model if not already present
if [ ! -f "audio_processor/tiny.pt" ]; then
    echo "Setting up audio processor and downloading model..."
    mkdir -p audio_processor
    cd audio_processor
    wget https://openaipublic.azureedge.net/main/whisper/models/65147644a518d12f04e32d6f3b26facc3f8dd46e5390956a9424a650c0ce22b9/tiny.pt
    check_command "download tiny.pt"
else
    echo "Audio processor model already exists. Skipping download."
fi

# Install system-wide FFmpeg if not already installed
if ! dpkg -l | grep -q ffmpeg; then
    echo "Updating system and installing FFmpeg..."
    sudo apt update && sudo apt install -y ffmpeg
    check_command "install ffmpeg"
else
    echo "FFmpeg is already installed system-wide. Skipping installation."
fi

echo "Setup complete!"
