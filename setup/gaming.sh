# Install nvidia driver and linux headers
wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install linux-headers-$(uname -r)
sudo apt install nvidia-open

sudo dpkg --add-architecture i386
sudo apt update
sudo apt install nvidia-driver-libs:i386 --install-recommends


sudo apt install \
libvulkan1 libvulkan1:i386 \
nvidia-vulkan-icd \
nvidia-vulkan-icd:i386 \
vulkan-tools \
steam \



# Lutris
#echo -e "Types: deb\nURIs: https://download.opensuse.org/repositories/home:/strycore:/lutris/Debian_13/\nSuites: ./\nComponents: \nSigned-By: /etc/apt/keyrings/lutris.gpg" | sudo tee /etc/apt/sources.list.d/lutris.sources > /dev/null
#wget -q -O- https://download.opensuse.org/repositories/home:/strycore:/lutris/Debian_13/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/lutris.gpg
#sudo apt update
#sudo apt install lutris




