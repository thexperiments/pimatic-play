pimatic-play
=======================

A plugin for playing sounds in pimatic.
Requires a suitable player installed on your machine:

afplay (osx available by default)
mplayer (best for raspberry)
mpg123
mpg321
play


Configuration
-------------
You can load the backend by editing your `config.json` to include:

    {
      "plugin": "play",
    }

in the `plugins` section. For all configuration options see 
[play-config-schema](play-config-schema.coffee)

Currently you can play sounds via action handler within rules.

Example:
--------

    if it is 08:00 play "./alarm.wav"

in general: if X then play "path/to/file.wav"

currently the option for setting a player is not implemented!