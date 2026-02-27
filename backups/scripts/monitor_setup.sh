sudo apt install autorandr

# Setup first monitor
xrandr --output DP-0 --auto --primary
# xrandr --output DP-0 --mode 1920x1080 --rate 144 --primary

# Save preset as single monitor setup
autorandr --save single

# Setup secondary monitor to the right
xrandr \
  --output DP-4 --auto --right-of DP-0 \
  --output DP-0 --auto --primary

# Save preset as dual monitor setup
autorandr --save dual
