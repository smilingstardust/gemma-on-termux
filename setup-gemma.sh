#!/data/data/com.termux/files/usr/bin/bash

# Exit on error, undefined var, or pipe failure
set -euo pipefail

# Use non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# 1️⃣ Step 1/7: Create setup directory
echo "[1/7] Creating setup-gemma directory..."
mkdir -p "$HOME/setup-gemma"
cd "$HOME/setup-gemma"

# 2️⃣ Step 2/7: Update package lists
echo "[2/7] Updating package lists..."
apt-get update -y > /dev/null 2>&1

# 3️⃣ Step 3/7: Upgrade existing packages
echo "[3/7] Upgrading installed packages..."
apt-get upgrade -y -o Dpkg::Options::="--force-confnew" > /dev/null 2>&1

# 4️⃣ Step 4/7: Install dependencies
echo "[4/7] Installing dependencies (git, cmake, curl)..."
apt-get install -y git cmake curl > /dev/null 2>&1

# 5️⃣ Step 5/7: Clone llama.cpp repository
echo "[5/7] Cloning llama.cpp..."
rm -rf llama.cpp
git clone https://github.com/ggml-org/llama.cpp --progress

# 6️⃣ Step 6/7: Build llama.cpp
echo "[6/7] Building llama.cpp..."
cd llama.cpp
cmake -B build -DGGML_CPU_KLEIDIAI=ON > /dev/null 2>&1
cmake --build build --config Release > /dev/null 2>&1

# 7️⃣ Step 7/7: Download Gemma model with progress bar
echo "[7/7] Downloading Gemma model..."
curl -L --progress-bar \
  https://huggingface.co/AsmitPS/gemma3-1b-it-Q4_K_M-gguf/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf \
  -o "$HOME/setup-gemma/gemma3.gguf"

# 🚀 Create launcher script
echo "Creating launcher script..."
mkdir -p "$HOME/.termux"
cat > "$HOME/.termux/gemma" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
"$HOME/setup-gemma/llama.cpp/build/bin/llama-cli" -m "$HOME/setup-gemma/gemma3.gguf"
EOF
chmod +x "$HOME/.termux/gemma"

# 🔧 Add launcher to PATH
if ! grep -qxF 'export PATH=$PATH:~/.termux' "$HOME/.bashrc"; then
  echo 'export PATH=$PATH:~/.termux' >> "$HOME/.bashrc"
fi

# Final message
echo "✅ Setup complete! Run the model anytime with: gemma"
