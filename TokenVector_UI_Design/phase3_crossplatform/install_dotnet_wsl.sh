#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# install_dotnet_wsl.sh — Cài .NET 8 SDK vào WSL2 Ubuntu để test TokenVector trên Linux
#
# CÁCH DÙNG (trong WSL2 terminal):
#   chmod +x install_dotnet_wsl.sh
#   ./install_dotnet_wsl.sh
#
# Sau khi chạy xong, bạn có thể test platform_patch.py ngay trong WSL2:
#   python3 TokenVector_UI_Design/phase3_crossplatform/platform_patch.py

set -e  # Dừng ngay nếu có lỗi

echo "=========================================="
echo " TokenVector — WSL2 .NET 8 SDK Installer"
echo "=========================================="
echo ""

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi

echo "[1/4] Detected OS: $DISTRO"

# Cài .NET 8 SDK theo distro
if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
    echo "[2/4] Updating apt packages..."
    sudo apt-get update -q

    echo "[3/4] Installing .NET 8 SDK..."
    sudo apt-get install -y dotnet-sdk-8.0

elif [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ]; then
    echo "[3/4] Installing .NET 8 SDK (dnf)..."
    sudo dnf install -y dotnet-sdk-8.0

elif [ "$DISTRO" = "arch" ]; then
    echo "[3/4] Installing .NET 8 SDK (pacman)..."
    sudo pacman -Sy --noconfirm dotnet-sdk-8.0

else
    echo "[3/4] Unknown distro. Trying manual install from Microsoft..."
    wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --channel 8.0
    echo 'export PATH="$PATH:$HOME/.dotnet"' >> ~/.bashrc
    export PATH="$PATH:$HOME/.dotnet"
fi

echo ""
echo "[4/4] Verifying installation..."
DOTNET_VER=$(dotnet --version 2>/dev/null || echo "NOT FOUND")
echo "      dotnet version: $DOTNET_VER"

# Tìm ilasm
ILASM_PATH=$(find /usr/share/dotnet/sdk -name "ilasm" 2>/dev/null | head -1)
if [ -n "$ILASM_PATH" ]; then
    echo "      ilasm found at: $ILASM_PATH"
else
    ILASM_PATH=$(find ~/.dotnet/sdk -name "ilasm" 2>/dev/null | head -1)
    if [ -n "$ILASM_PATH" ]; then
        echo "      ilasm found at: $ILASM_PATH"
    else
        echo "      [WARN] ilasm not found — may need to run: dotnet tool restore"
    fi
fi

echo ""
echo "=========================================="
echo " Installation complete!"
echo " Next steps:"
echo "   cd /mnt/d/Claude\\ AI\\ Project/TokenVector"
echo "   python3 TokenVector_UI_Design/phase3_crossplatform/platform_patch.py"
echo "=========================================="
