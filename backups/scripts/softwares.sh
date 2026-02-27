sudo apt install \
gnome-software \
gnome-software-plugin-flatpak \
flatpak 

# video thumbnails
sudo apt install ffmpegthumbnailer ffmpeg libavcodec-extra


#archive extraction
sudo apt install file-roller xarchiver p7zip-full unzip unrar-free


sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y org.videolan.VLC
flatpak install -y com.obsproject.Studio
flatpak install -y org.qbittorrent.qBittorrent
flatpak install -y org.gnome.Brasero
flatpak install -y com.vysp3r.ProtonPlus
flatpak install -y com.google.Chrome
flatpak install -y com.microsoft.Edge

flatpak install -y org.gimp.GIMP
flatpak install -y org.libreoffice.LibreOffice
flatpak install -y org.inkscape.Inkscape
flatpak install -y com.heroicgameslauncher.hgl
flatpak install -y com.github.tchx84.Flatseal


sudo apt install \
gnome-disk-utility \
fastfetch \
nwg-look \
mpv \
imagemagick \
libnotify-bin \
media-info \

# Setup python apps
sudo apt install \
python3-pip \
pipx
pipx ensurepath
source ~/.bashrc

pipx install pywal



#yazi
sudo apt install ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick
wget https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.deb
sudo dpkg -i yazi-x86_64-unknown-linux-gnu.deb





