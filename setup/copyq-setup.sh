sudo apt install -y copyq

cat > ~/.config/systemd/user/copyq.service << 'EOF'
[Unit]
Description=CopyQ clipboard manager
After=graphical-session.target

[Service]
ExecStart=/usr/bin/copyq
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now copyq.service
