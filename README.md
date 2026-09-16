# debi3n
Setup debian with i3 desktop




# Firefox display scaling
about:config
layout.css.devPixelsPerPx


# Display scale flatpak apps

flatpak override --user --reset org.kde.kdenlive
flatpak override --user --env=QT_SCALE_FACTOR=1.5 org.kde.kdenlive
