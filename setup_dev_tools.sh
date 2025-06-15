#!/bin/bash

# Script Purpose: Automates the setup of essential development tools for this project.
# Assumptions:
#   - Running on a Debian-based Linux distribution (e.g., Ubuntu).
#   - The user has sudo privileges for installing packages.
#   - Internet connection is available for downloading tools.
#
# Versioning Notes:
#   - Flutter SDK: Pinned to a specific version defined by FLUTTER_VERSION.
#   - Firebase CLI: Installs the latest stable version via its official script.
#   - Google Cloud SDK (gcloud CLI): Installs the latest stable version via its official package repository.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting development tools setup..."

# --- Prerequisites ---
echo "Installing common prerequisites..."
# These packages are generally useful and cover dependencies for curl, unzip, git, etc.
sudo apt-get update -y
sudo apt-get install -y curl unzip xz-utils git apt-transport-https ca-certificates gnupg wget software-properties-common

# --- Flutter SDK ---
# Flutter version is pinned for consistent development environments.
FLUTTER_VERSION="3.22.2"
FLUTTER_INSTALL_DIR="$HOME/sdks/flutter" # User-specific install directory to avoid needing sudo for Flutter itself.
echo "Installing Flutter SDK version $FLUTTER_VERSION..."

if [ -d "$FLUTTER_INSTALL_DIR" ]; then
  echo "Flutter directory $FLUTTER_INSTALL_DIR already exists. Skipping download and extraction."
else
  mkdir -p "$HOME/sdks" # Ensure the parent SDKs directory exists.
  # Download and extract Flutter SDK.
  wget "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -O "$HOME/sdks/flutter.tar.xz"
  tar xf "$HOME/sdks/flutter.tar.xz" -C "$HOME/sdks"
  rm "$HOME/sdks/flutter.tar.xz" # Clean up downloaded archive.
fi

# Add Flutter to PATH for the current session.
# Persistent PATH modification should be done by the user in their .bashrc or .zshrc.
echo "Adding Flutter to PATH for current session: $FLUTTER_INSTALL_DIR/bin"
export PATH="$PATH:$FLUTTER_INSTALL_DIR/bin"

# Pre-download Flutter development binaries.
echo "Running flutter precache..."
flutter precache

echo "Flutter SDK installed successfully."
flutter --version

# --- Firebase CLI ---
# Installs the latest stable version from Firebase's official script.
echo "Installing Firebase CLI..."
if command -v firebase &> /dev/null
then
    echo "Firebase CLI already installed. Skipping."
else
    # The official Firebase CLI installer.
    curl -sL https://firebase.tools | bash
fi
echo "Firebase CLI installed successfully."
firebase --version

# --- Google Cloud SDK (gcloud CLI) ---
# Installs the latest stable version from Google Cloud's official package repository.
echo "Installing Google Cloud SDK..."

if command -v gcloud &> /dev/null
then
    echo "Google Cloud SDK already installed. Skipping."
else
    # Add the gcloud CLI distribution URI as a package source.
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    # Import the Google Cloud public key.
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

    # Update package list and install the gcloud CLI.
    sudo apt-get update -y && sudo apt-get install -y google-cloud-cli
fi

echo "Google Cloud SDK installed successfully."
gcloud --version

echo "--- Setup Complete ---"
echo "Please ensure the following directories are added to your PATH in your shell's rc file (e.g., .bashrc, .zshrc) for persistent access:"
echo "  Flutter: $FLUTTER_INSTALL_DIR/bin"
echo "  Firebase CLI: (usually handled by its installer, typically adds to ~/.bashrc or similar during its first run/setup if installed via its standalone binary script)"
echo "  Google Cloud SDK: (usually handled by its installer, often suggests sourcing a file like 'google-cloud-sdk/path.bash.inc')"
echo "You might need to start a new terminal session or source your shell configuration file (e.g., 'source ~/.bashrc') for all changes to take full effect."
