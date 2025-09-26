#!/bin/bash

# Triangle Splatting Quick Setup Script for Ubuntu
# Run this script via SSH or in a terminal

set -e  # Exit on error

echo "========================================"
echo "Triangle Splatting Setup Script"
echo "========================================"

# Step 1: Check CUDA availability
echo "Step 1: Checking CUDA..."
if ! command -v nvcc &> /dev/null; then
    echo "WARNING: CUDA not found. Please ensure CUDA is installed."
    echo "You can install CUDA 12.6 from: https://developer.nvidia.com/cuda-downloads"
    echo "Continuing setup anyway..."
else
    nvcc --version
fi

# Step 2: Install system dependencies
echo -e "\nStep 2: Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y git build-essential python3.11 python3.11-venv python3.11-dev wget curl

# Step 3: Install Micromamba if not present
echo -e "\nStep 3: Setting up Micromamba..."
if ! command -v micromamba &> /dev/null; then
    echo "Installing Micromamba..."
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
    mkdir -p ~/micromamba
    ./bin/micromamba shell init -s bash -p ~/micromamba
    source ~/.bashrc
    export PATH="$HOME/micromamba/bin:$PATH"
else
    echo "Micromamba already installed"
fi

# Step 4: Clone the repository with submodules
echo -e "\nStep 4: Cloning Triangle Splatting repository..."
if [ -d "triangle-splatting" ]; then
    echo "Repository already exists. Pulling latest changes..."
    cd triangle-splatting
    git pull
    git submodule update --init --recursive
else
    git clone https://github.com/trianglesplatting/triangle-splatting --recursive
    cd triangle-splatting
fi

# Step 5: Download requirements.yaml if not present
echo -e "\nStep 5: Setting up environment..."
if [ ! -f "requirements.yaml" ]; then
    echo "Creating requirements.yaml..."
    cat > requirements.yaml << 'EOF'
name: triangle-splatting
channels:
  - conda-forge
  - pytorch
  - nvidia
dependencies:
  - python=3.11
  - pytorch::pytorch=2.4.1
  - pytorch::torchvision
  - conda-forge::tqdm
  - conda-forge::matplotlib
  - conda-forge::plyfile
  - conda-forge::opencv
  - conda-forge::imageio
  - conda-forge::imageio-ffmpeg
  - conda-forge::lpips
  - pip
  - pip:
    - submodules/diff-surfel-rasterization
    - submodules/simple-knn
EOF
fi

# Step 6: Create and activate the environment
echo -e "\nStep 6: Creating Micromamba environment..."
eval "$(micromamba shell hook --shell bash)"
micromamba create -f requirements.yaml -y
micromamba activate triangle-splatting

# Step 7: Compile CUDA kernels
echo -e "\nStep 7: Compiling CUDA kernels..."
if [ -f "compile.sh" ]; then
    bash compile.sh
else
    echo "Creating compile.sh..."
    cat > compile.sh << 'EOF'
#!/bin/bash
cd submodules/diff-surfel-rasterization
python setup.py install
cd ../..
EOF
    bash compile.sh
fi

# Step 8: Install simple-knn
echo -e "\nStep 8: Installing simple-knn..."
cd submodules/simple-knn
pip install .
cd ../..

# Step 9: Verify installation
echo -e "\nStep 9: Verifying installation..."
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"

echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "To use Triangle Splatting:"
echo "1. Activate the environment: micromamba activate triangle-splatting"
echo "2. Train a model: python train.py -s <path_to_scenes> -m <output_model_path> --eval"
echo "3. Render: python render.py -m <path_to_model>"
echo ""
echo "For Jupyter Notebook usage:"
echo "1. Install kernel: python -m ipykernel install --user --name=triangle-splatting"
echo "2. Select 'triangle-splatting' kernel in Jupyter"
