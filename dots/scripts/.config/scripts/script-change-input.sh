#!/bin/bash
current=$(ibus engine)
if [ "$current" = "ibus-avro" ]; then
    ibus engine xkb:us::eng
else
    ibus engine ibus-avro
fi
