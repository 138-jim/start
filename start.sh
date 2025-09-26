#!/bin/bash

# Triangle Splatting Quick Setup Script for Ubuntu
# Fixed version with proper micromamba/conda handling

set -e  # Exit on error

echo "========================================"
echo "Triangle Splatting Setup Script"
echo "========================================"

# Step 1: Check CUDA availability
echo "Step 1: Checking CUDA..."
if ! command -v nvcc &> /dev/null; then
    echo "WARNING: CUDA not found. Please ensure CUDA is installed."
    echo "You can install CUDA from: https://developer.nvidia.com/cuda-downloads"
    echo "Continuing setup anyway..."
else
    nvcc --version
fi

# Step 2: Install system dependencies
echo -e "\nStep 2: Installing system dependencies..."
apt-get update
apt-get install -y git build-essential python3.11 python3.11-venv python3.11-dev wget curl

# Step 3: Clone the repository with submodules
echo -e "\nStep 3: Cloning Triangle Splatting repository..."
if [ -d "triangle-splatting" ]; then
    echo "Repository already exists. Pulling latest changes..."
    cd triangle-splatting
    git pull
    git submodule update --init --recursive
else
    git clone https://github.com/trianglesplatting/triangle-splatting --recursive
    cd triangle-splatting
fi

# Step 4: Setup Python environment (choose method)
echo -e "\nStep 4: Setting up Python environment..."
echo "Choose installation method:"
echo "1) Use pip with venv (simpler, recommended)"
echo "2) Try to install/use micromamba"
echo "3) Use existing conda/mamba"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "Using Python venv with pip..."
        python3.11 -m venv venv
        source venv/bin/activate
        
        # Upgrade pip
        pip install --upgrade pip
        
        # Install PyTorch with CUDA support
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
        
        # Install other dependencies
        pip install tqdm matplotlib plyfile opencv-python imageio imageio-ffmpeg lpips
        
        # Install submodules
        cd submodules/diff-surfel-rasterization
        pip install .
        cd ../simple-knn
        pip install .
        cd ../..
        
        echo "Environment setup complete with venv!"
        echo "To activate: source venv/bin/activate"
        ;;
        
    2)
        echo "Installing Micromamba..."
        # Install micromamba using the official installer
        "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
        
        # Source the shell configuration
        source ~/.bashrc
        
        # Create environment from requirements
        echo "Creating micromamba environment..."
        
        # Create a minimal requirements.yaml if it doesn't exist
        if [ ! -f "requirements.yaml" ]; then
            cat > requirements.yaml << 'EOF'
name: triangle-splatting
channels:
  - conda-forge
  - pytorch
  - nvidia
dependencies:
  - python=3.11
  - pytorch::pytorch
  - pytorch::torchvision
  - conda-forge::tqdm
  - conda-forge::matplotlib
  - conda-forge::plyfile
  - conda-forge::opencv
  - conda-forge::imageio
  - conda-forge::imageio-ffmpeg
  - pip
  - pip:
    - lpips
EOF
        fi
        
        micromamba create -f requirements.yaml -y
        eval "$(micromamba shell hook --shell bash)"
        micromamba activate triangle-splatting
        
        # Install submodules
        cd submodules/diff-surfel-rasterization
        pip install .
        cd ../simple-knn
        pip install .
        cd ../..
        
        echo "Environment setup complete with micromamba!"
        echo "To activate: micromamba activate triangle-splatting"
        ;;
        
    3)
        echo "Using existing conda/mamba installation..."
        
        # Check for conda or mamba
        if command -v conda &> /dev/null; then
            CONDA_CMD="conda"
        elif command -v mamba &> /dev/null; then
            CONDA_CMD="mamba"
        else
            echo "No conda or mamba found! Please install one first."
            exit 1
        fi
        
        # Create environment
        $CONDA_CMD create -n triangle-splatting python=3.11 -y
        source $(conda info --base)/etc/profile.d/conda.sh
        conda activate triangle-splatting
        
        # Install PyTorch
        $CONDA_CMD install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y
        
        # Install other dependencies
        $CONDA_CMD install tqdm matplotlib plyfile opencv imageio imageio-ffmpeg -c conda-forge -y
        pip install lpips
        
        # Install submodules
        cd submodules/diff-surfel-rasterization
        pip install .
        cd ../simple-knn
        pip install .
        cd ../..
        
        echo "Environment setup complete with $CONDA_CMD!"
        echo "To activate: conda activate triangle-splatting"
        ;;
        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Step 5: Verify installation
echo -e "\nStep 5: Verifying installation..."
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"

echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "To use Triangle Splatting:"
echo "1. Activate the environment (see message above)"
echo "2. Train a model: python train.py -s <path_to_scenes> -m <output_model_path> --eval"
echo "3. Render: python render.py -m <path_to_model>"
echo ""
echo "For Jupyter Notebook usage:"
echo "1. Install kernel: python -m ipykernel install --user --name=triangle-splatting"
echo "2. Select 'triangle-splatting' kernel in Jupyter"
