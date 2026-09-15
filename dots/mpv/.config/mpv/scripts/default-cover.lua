local mp = require 'mp'
local home = os.getenv("HOME")
local cover = home .. "/.config/mpv/default_cover.png"

mp.register_event("file-loaded", function()
    if mp.get_property("video") == "no" then
        mp.commandv("video-add", cover)
    end
end)

