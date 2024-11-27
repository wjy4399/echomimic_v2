#!/bin/bash

# Function for checking command success
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error during $1. Exiting."
        exit 1
    fi
}

# Upgrade pip and install dependencies
echo "Upgrading pip..."
pip install pip -U
check_command "pip upgrade"

echo "Installing dependencies..."
if ! pip show torch &>/dev/null; then
    pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 xformers==0.0.28.post3 --index-url https://download.pytorch.org/whl/cu124
    check_command "torch dependencies installation"
else
    echo "Torch dependencies already installed. Skipping."
fi

if ! pip show torchao &>/dev/null; then
    pip install torchao --index-url https://download.pytorch.org/whl/nightly/cu124
    check_command "torchao installation"
else
    echo "torchao already installed. Skipping."
fi

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    check_command "installing requirements"
else
    echo "requirements.txt not found. Skipping."
fi

if ! pip show facenet_pytorch &>/dev/null; then
    pip install --no-deps facenet_pytorch==2.6.0
    check_command "facenet_pytorch installation"
else
    echo "facenet_pytorch already installed. Skipping."
fi

# Install FFmpeg
if ! command -v ffmpeg &>/dev/null; then
    echo "Installing FFmpeg..."
    if [ ! -f "ffmpeg-4.4-amd64-static.tar.xz" ]; then
        wget https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.4-amd64-static.tar.xz
        check_command "downloading FFmpeg"
    fi

    if [ ! -d "ffmpeg-4.4-amd64-static" ]; then
        tar -xvf ffmpeg-4.4-amd64-static.tar.xz
        check_command "extracting FFmpeg"
    fi

    export FFMPEG_PATH="$PWD/ffmpeg-4.4-amd64-static"
    echo "FFmpeg installed at $FFMPEG_PATH"
else
    echo "FFmpeg already installed. Skipping."
fi

# Initialize git LFS and clone pretrained weights
if ! git lfs env &>/dev/null; then
    echo "Initializing Git LFS..."
    git lfs install
    check_command "Git LFS initialization"
else
    echo "Git LFS already initialized. Skipping."
fi

if [ ! -d "pretrained_weights" ]; then
    echo "Cloning pretrained weights..."
    git clone https://huggingface.co/BadToBest/EchoMimicV2 pretrained_weights
    check_command "cloning pretrained weights"
else
    echo "Pretrained weights already exist. Skipping."
fi

# Clone additional repositories
if [ -d "pretrained_weights" ]; then
    cd pretrained_weights

    if [ ! -d "sd-vae-ft-mse" ]; then
        echo "Cloning sd-vae-ft-mse..."
        git clone https://huggingface.co/stabilityai/sd-vae-ft-mse
        check_command "cloning sd-vae-ft-mse"
    else
        echo "sd-vae-ft-mse already exists. Skipping."
    fi

    if [ ! -d "sd-image-variations-diffusers" ]; then
        echo "Cloning sd-image-variations-diffusers..."
        git clone https://huggingface.co/lambdalabs/sd-image-variations-diffusers
        check_command "cloning sd-image-variations-diffusers"
    else
        echo "sd-image-variations-diffusers already exists. Skipping."
    fi

    cd ..
else
    echo "Error: pretrained_weights directory not found. Skipping additional repository cloning."
fi

# Set up audio processor and download model
if [ ! -d "audio_processor" ]; then
    echo "Setting up audio processor..."
    mkdir audio_processor
fi

if [ ! -f "audio_processor/tiny.pt" ]; then
    wget https://openaipublic.azureedge.net/main/whisper/models/65147644a518d12f04e32d6f3b26facc3f8dd46e5390956a9424a650c0ce22b9/tiny.pt -O audio_processor/tiny.pt
    check_command "downloading tiny.pt"
else
    echo "Audio processor model already exists. Skipping download."
fi

# Install FFmpeg system-wide if not already installed
if ! dpkg -l | grep -q ffmpeg; then
    echo "Installing FFmpeg system-wide..."
    sudo apt update && sudo apt install -y ffmpeg
    check_command "system-wide FFmpeg installation"
else
    echo "FFmpeg already installed system-wide. Skipping."
fi

echo "Setup complete!"
