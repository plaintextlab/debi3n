# Theme
sudo apt install gtk2-engines-murrine

git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git 
cd Gruvbox-GTK-Theme/themes
./install.sh
cd ../..
rm -rf Gruvbox-GTK-Theme

sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
flatpak override --user --filesystem=xdg-config/gtk-4.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0

# Icon
wget "$(curl -s https://api.github.com/repos/SylEleuth/gruvbox-plus-icon-pack/releases/latest \
  | grep "browser_download_url.*zip" \
  | cut -d '"' -f 4)"

unzip gruvbox-plus-icon-pack-*.zip
cp -rv Gruvbox-Plus-Dark Gruvbox-Plus-Light ~/.local/share/icons
rm gruvbox-plus-icon-pack-*.zip
rm -rf Gruvbox-Plus-Dark
rm -rf Gruvbox-Plus-Light