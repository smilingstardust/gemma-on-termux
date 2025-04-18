#!/data/data/com.termux/files/usr/bin/bash

pkg install pv -y


set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

# Logging only script's output
exec > >(tee -a ~/setup-gemma-install.log) 2>&1

# -----------------------------
# 📂 Create isolated directory
# -----------------------------
echo "📂 Creating setup-gemma directory..."
mkdir -p ~/setup-gemma
cd ~/setup-gemma || { echo "❌ Failed to enter setup-gemma directory"; exit 1; }

# -----------------------------
# 🔄 Update and upgrade
# -----------------------------
echo "🔄 Updating and upgrading packages..."
{
    apt-get update
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
} | pv -p -t -e -b > /dev/null || echo "⚠️  Some packages were held back or had minor warnings."

# -----------------------------
# 📥 Install required packages
# -----------------------------
echo "📦 Installing dependencies..."
{
    apt-get install -y -o Dpkg::Options::="--force-confnew" git cmake curl
} | pv -p -t -e -b > /dev/null || { echo "❌ Package install failed"; exit 1; }

# -----------------------------
# 🧠 Clone llama.cpp
# -----------------------------
echo "🔁 Cloning llama.cpp..."
{
    git clone https://github.com/ggml-org/llama.cpp
} | pv -p -t -e -b > /dev/null || { echo "❌ Failed to clone llama.cpp"; exit 1; }

cd llama.cpp || { echo "❌ Failed to enter llama.cpp directory"; exit 1; }

# -----------------------------
# ⚙️ Build project
# -----------------------------
echo "⚙️ Building llama.cpp..."
{
    cmake -B build -DGGML_CPU_KLEIDIAI=ON
    cmake --build build --config Release
} | pv -p -t -e -b > /dev/null || { echo "❌ Build failed"; exit 1; }

# -----------------------------
# ⬇️ Download model with progress bar and ETA
# -----------------------------
echo "⬇️ Downloading Gemma model..."
curl -L https://huggingface.co/AsmitPS/gemma3-1b-it-Q4_K_M-gguf/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf -o ~/setup-gemma/gemma3.gguf --progress-bar || { echo "❌ Model download failed"; exit 1; }

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
echo 'export PATH=$PATH:~/.termux' >> ~/.bashrc
source ~/.bashrc || true

echo "✅ Setup complete! Run the model with: gemma"
