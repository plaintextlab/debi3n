sudo apt install \
pipewire \
pipewire-audio \
pipewire-pulse \
wireplumber \
pulseaudio-utils \
playerctl

systemctl --user --now enable \
pipewire \
pipewire-pulse \
wireplumber


