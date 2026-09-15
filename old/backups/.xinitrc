#exec i3
#using dbus to run i3, this is for debian 13, otherwise some apps will launch very very slowly. The above line works on arch
exec dbus-run-session -- systemd-cat --identifier=i3 i3

