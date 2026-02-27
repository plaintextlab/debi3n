sudo apt install \
ddcutil \
i2c-tools

sudo modprobe i2c-dev
echo i2c-dev | sudo tee /etc/modules-load.d/i2c.conf
sudo usermod -aG i2c $USER
