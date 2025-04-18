#!/data/data/com.termux/files/usr/bin/bash

set -e  # Stop on first error
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# Logging everything for debugging if needed
exec > >(tee -a ~/setup-gemma-install.log) 2>&1

# -----------------------------
# 📦 Create isolated directory
# -----------------------------
mkdir -p ~/setup-gemma
cd ~/setup-gemma || exit 1

# -----------------------------
# 🔄 Update and upgrade
# -----------------------------
echo "🔄 Updating system..."
apt update && apt upgrade -y

# -----------------------------
# 📥 Install required packages
# -----------------------------
echo "📦 Installing dependencies..."
apt install -y -o Dpkg::Options::="--force-confnew" git cmake curl

# -----------------------------
# 🧠 Clone llama.cpp
# -----------------------------
echo "🔁 Cloning llama.cpp..."
if [ -d "llama.cpp" ]; then
    echo "⚠️  llama.cpp already exists. Skipping clone."
else
    git clone https://github.com/ggml-org/llama.cpp
fi

cd llama.cpp || exit 1

# -----------------------------
# ⚙️ Build project
# -----------------------------
echo "⚙️ Building llama.cpp..."
cmake -B build -DGGML_CPU_KLEIDIAI=ON
cmake --build build --config Release

# -----------------------------
# ⬇️ Download model
# -----------------------------
echo "⬇️ Downloading Gemma model..."
curl -L https://huggingface.co/AsmitPS/gemma3-1b-it-Q4_K_M-gguf/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf -o ~/setup-gemma/gemma3.gguf

# -----------------------------
# 🚀 Create launcher script
# -----------------------------
echo "🧾 Creating launcher..."
mkdir -p ~/.termux

cat << 'EOF' > ~/.termux/gemma
#!/data/data/com.termux/files/usr/bin/bash
~/setup-gemma/llama.cpp/build/bin/llama-cli -m ~/setup-gemma/gemma3.gguf
EOF

chmod +x ~/.termux/gemma

# -----------------------------
# 🔧 Add to PATH (if not already)
# -----------------------------
if ! grep -q 'export PATH=$PATH:~/.termux' ~/.bashrc; then
    echo 'export PATH=$PATH:~/.termux' >> ~/.bashrc
fi

source ~/.bashrc

echo "✅ Setup complete! Run the model with: gemma"
