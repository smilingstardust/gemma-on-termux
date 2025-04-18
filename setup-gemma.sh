#!/data/data/com.termux/files/usr/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Update and upgrade packages
apt update && apt upgrade -y
# Install necessary packages
apt install -y -o Dpkg::Options::="--force-confnew" git cmake
# Clone the llama.cpp repository
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
# Build the project with Kleidia CPU support
cmake -B build -DGGML_CPU_KLEIDIAI=ON
cmake --build build --config Release
# Download your GGUF model from HuggingFace
curl -L https://huggingface.co/AsmitPS/gemma3-1b-it-Q4_K_M-gguf/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf -o ~/gemma3.gguf
# Create launcher script
cat << 'EOF' > ~/gemma.sh
#!/data/data/com.termux/files/usr/bin/bash
~/llama.cpp/build/bin/llama-cli -m ~/gemma3.gguf
EOF
# Move it to .termux for PATH access
mkdir -p ~/.termux
mv ~/gemma.sh ~/.termux/gemma
chmod +x ~/.termux/gemma
# Add to PATH in bashrc if not already present
if ! grep -q 'export PATH=$PATH:~/.termux' ~/.bashrc; then
    echo 'export PATH=$PATH:~/.termux' >> ~/.bashrc
fi
# Reload shell config
source ~/.bashrc
echo " Setup complete! Now you can run the model using the command: gemma"
