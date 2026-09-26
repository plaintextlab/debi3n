#Install nerd font

mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip
rm JetBrainsMono.zip

sudo apt update

sudo apt install -y fonts-liberation fonts-dejavu fonts-freefont-ttf fonts-noto fonts-noto-color-emoji fonts-noto-cjk fontconfig ttf-mscorefonts-installer

# Install DOS font for UI
cp ~/debi3n/setup/fonts/moreperfectdosvga.ttf ~/.local/share/fonts/

fc-cache -fv