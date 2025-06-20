#!/bin/bash

set -eu # Exit on error and undefined variables

echo "##########################################"
echo "Be Careful this will override your Rice!! "
echo "##########################################"
echo

echo "Installing Necessary Packages"
echo "#############################"
echo

echo "Native Packages..."
echo

sudo pacman -S --noconfirm --needed imagemagick kvantum unzip jq xmlstarlet meld fastfetch gtk-engine-murrine gtk-engines ttf-hack-nerd ttf-fira-code kdeconnect ttf-terminus-nerd noto-fonts-emoji ttf-meslo-nerd

echo

echo "AUR Packages..."
echo

# Check if yay or paru is installed
if pacman -Qs yay &> /dev/null; then
  aur_helper="yay"
elif pacman -Qs paru &> /dev/null; then
  aur_helper="paru"
else
  echo "Neither yay nor paru is installed. Please select one to install:"
  echo
  echo "1. Install yay"
  echo "2. Install paru"
  echo
  read -p "Enter your choice (1/2): " choice

  case "$choice" in
    1)
      echo "Installing yay..."
      echo
      git clone https://aur.archlinux.org/yay.git
      cd yay
      makepkg -si
      cd ..
      rm -rf yay
      aur_helper="yay"
      ;;
    2)
      echo "Installing paru..."
      echo
      sudo pacman -S --noconfirm rust
      git clone https://aur.archlinux.org/paru.git
      cd paru
      makepkg -si
      cd ..
      rm -rf paru
      aur_helper="paru"
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

echo "Selected AUR helper: $aur_helper"
echo

# Install packages using the detected AUR helper
$aur_helper -S --noconfirm --needed ttf-meslo-nerd-font-powerlevel10k tela-circle-icon-theme-blue pacseek

sleep 2
echo

echo "Creating Backup & Applying new Rice, hold on..."
echo "###############################################"

cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H.%M.%S) && cp -Rf Configs/Home/. ~
sudo cp -Rf Configs/System/. / && sudo cp -Rf Configs/Home/. /root/

sleep 2
echo

echo "Adding Fastfetch to your shell configuration"
echo

# Function to add fastfetch to a shell configuration file
add_fastfetch() {
  local shell_rc="$1"
  if ! grep -Fxq 'fastfetch' "$HOME/$shell_rc"; then
    echo '' >> "$HOME/$shell_rc"
    echo 'fastfetch' >> "$HOME/$shell_rc"
    echo
    echo "fastfetch has been added to your $shell_rc and will run on Terminal launch."
  else
    echo "fastfetch is already set to run on Terminal launch in $shell_rc."
  fi
}

# Detect the current shell
current_shell=$(basename "$SHELL")

# Prompt the user
read -p "Do you want to enable fastfetch to run on Terminal launch? (y/n): " response

case "$response" in
  [yY])
    if [ "$current_shell" = "zsh" ]; then
      add_fastfetch ".zshrc"
    elif [ "$current_shell" = "bash" ]; then
      add_fastfetch ".bashrc"
    else
      echo "Unsupported shell: $current_shell"
    fi
    ;;
  [nN])
    echo "fastfetch will not be added to your shell configuration."
    ;;
  *)
    echo "Invalid response. Please enter y or n."
    ;;
esac

sleep 2
echo

echo "Oh-My-Posh Setup."
echo
echo "Installing Oh-My-Posh"
$aur_helper -S --noconfirm --needed oh-my-posh-bin
echo
sleep 3

echo "Injecting OMP to .bashrc"

# Define the lines to be added
line1='# Oh-My-Posh Config'
line2='eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/distrous-xero-linux.omp.json)"'

# Define the .bashrc file
bashrc_file="$HOME/.bashrc"

# Function to add lines if not already present
add_lines() {
  if ! grep -qxF "$line1" "$bashrc_file"; then
    echo "" >> "$bashrc_file" # Add an empty line before line1
    echo "$line1" >> "$bashrc_file"
  fi
  if ! grep -qxF "$line2" "$bashrc_file"; then
    echo "$line2" >> "$bashrc_file"
    echo "" >> "$bashrc_file" # Add an empty line after line2
  fi
}

# Run the function to add lines
add_lines

echo "Oh-My-Posh injection complete."
sleep 3
echo

echo "Applying Grub Theme...."
echo "#######################"

# Check if GRUB is installed
if [ -d "/boot/grub" ]; then
    echo "GRUB detected. Proceeding with theme installation..."

    # Check if the theme folder exists and remove it
    if [ -d "/boot/grub/themes/Matrices-sidebar/" ]; then
        sudo rm -rf "/boot/grub/themes/Matrices-sidebar/"
    fi

    # Clone the repository and install the theme
    cd ~ && git clone https://github.com/yeyushengfan258/Matrix-grub-theme.git
    cd ~/Matrix-grub-theme/ && sudo ./install.sh -t sidebar -s 1080p
    cd ~ && rm -rf Matrix-grub-theme/
else
    echo "GRUB not detected. Skipping theme installation."
fi

sleep 2
echo

echo "Installing Orchis Theme"
echo "#######################"
echo

if cd ~ && git clone https://github.com/vinceliuice/Orchis-kde.git; then
   cd ~/Orchis-kde/ && sh install.sh
   cd ~ && rm -Rf Orchis-kde/
else
  echo "Failed to clone Orchis-kde theme"
  exit 1
fi

sleep 2
echo

echo "Installing & Applying GTK4 Theme "
echo "#################################"

# Check if ~/.themes directory exists, if not create it
if [ ! -d "$HOME/.themes" ]; then
  mkdir -p "$HOME/.themes"
  echo "Created ~/.themes directory"
fi

echo

# Prompt user for theme choice
echo "Choose your GTK Theme Variant :"
echo
echo "1) Default (Consistent)."
echo "2) Pure Black dark variant."
echo
read -p "Enter your choice (1 or 2): " choice

# Execute commands based on user choice
case $choice in
  1)
    echo "Installing Default/Consistent GTK theme..."
    echo
    cd ~ && git clone https://github.com/vinceliuice/Orchis-theme.git
    cd Orchis-theme/
    sh install.sh -l -f -c dark --tweaks primary -d $HOME/.themes
    sudo flatpak override --filesystem=xdg-config/gtk-3.0 && sudo flatpak override --filesystem=xdg-config/gtk-4.0
    cd ~ && rm -Rf Orchis-theme/
    echo
    echo "Standard/Consistent GTK theme installed successfully!"
    ;;
  2)
    echo "Installing Absolute Black GTK theme..."
    echo
    cd ~ && git clone https://github.com/vinceliuice/Orchis-theme.git
    cd ~/Orchis-theme/
    sh install.sh -l -f -c dark --tweaks black -d $HOME/.themes
    sudo flatpak override --filesystem=xdg-config/gtk-3.0 && sudo flatpak override --filesystem=xdg-config/gtk-4.0
    cd ~ && rm -Rf Orchis-theme/
    echo
    echo "Absolute Black GTK theme installed successfully!"
    ;;
  *)
    echo "Invalid choice. Please run the script again and select either 1 or 2."
    ;;
esac

echo
echo "Plz Reboot To Apply Settings..."
echo "###############################"
