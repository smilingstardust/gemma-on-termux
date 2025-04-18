#!/data/data/com.termux/files/usr/bin/bash

# Exit on error, undefined var, or pipe failure
set -euo pipefail

# Prevent interactive and pager prompts
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
unset DEB_PAGER

# 1️⃣ Step 1/7: Create setup directory
echo "[1/7] Creating setup-gemma directory..."
mkdir -p "$HOME/setup-gemma"
cd "$HOME/setup-gemma"

# 2️⃣ Step 2/7: Update package lists
echo "[2/7] Updating package lists..."
apt-get update -y >/dev/null 2>&1 || true

# 3️⃣ Step 3/7: Upgrade existing packages
echo "[3/7] Upgrading installed packages..."
apt-get upgrade -y -o Dpkg::Options::="--force-confnew" >/dev/null 2>&1 || true

# 4️⃣ Step 4/7: Install dependencies (git, cmake, curl, wget)
echo "[4/7] Installing dependencies (git, cmake, curl, wget)..."
apt-get install -y git cmake curl wget >/dev/null 2>&1

# 5️⃣ Step 5/7: Clone llama.cpp repository
echo "[5/7] Cloning llama.cpp..."
rm -rf llama.cpp
git clone https://github.com/ggml-org/llama.cpp --quiet >/dev/null 2>&1

# 6️⃣ Step 6/7: Build llama.cpp
echo "[6/7] Building llama.cpp..."
cd llama.cpp
cmake -B build -DGGML_CPU_KLEIDIAI=ON >/dev/null 2>&1
cmake --build build --config Release >/dev/null 2>&1

# 7️⃣ Step 7/7: Download Gemma model with one-line progress bar
echo "[7/7] Downloading Gemma model..."
wget --quiet --show-progress --progress=bar:force:noscroll \
  -O "$HOME/setup-gemma/gemma3.gguf" \
  https://huggingface.co/AsmitPS/gemma3-1b-it-Q4_K_M-gguf/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf

# 🚀 Create launcher script
echo "Creating launcher script..."
mkdir -p "$HOME/.termux"
cat > "$HOME/.termux/gemma" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
"$HOME/setup-gemma/llama.cpp/build/bin/llama-cli" -m "$HOME/setup-gemma/gemma3.gguf" > /dev/null 2>&1
EOF
chmod +x "$HOME/.termux/gemma"

# 🔧 Add launcher to PATH (idempotent)
echo 'export PATH=$PATH:~/.termux' >> "$HOME/.bashrc"
source "$HOME/.bashrc"

# Final message
echo "✅ Setup complete! Run the model anytime with: gemma"
