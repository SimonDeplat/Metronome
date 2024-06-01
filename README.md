# Metronome

#### Overview

Metronome is a metronome interface built with the [SuperCollider language](https://github.com/supercollider/supercollider).

You can find a preview of the software, and discuss the project, on the SuperCollider forum.

#### Installation

You will need SuperCollider to run this project. SuperCollider usage is beyond the scope of this documentation.

You also need to install the GraphicalModule quark to run it. You can use the dedicated interface, or evaluate `Quarks.install("GraphicalModule");` to do so. Then you'll have to recompile the library (re-open SuperCollider or use `CTRL + SHIFT + L`).

Then, evaluate `metronome.scd` within SuperCollider.

#### Usage

Metronome provides a piano roll for you to specify the notes the metronome should be playing. You can specify a root note, a mode and an octave to configure it so it plays the pattern you'd like. The piano roll starts at the scale's fifth, below the root note, and covers two octaves. If your diapason isn't 440HZ, you can modify it on top of the code.

You can modify the 'BPM rule' so that the tempo is increased by X every Nth cycle.

A preset system allows you to keep the state of the metronome in memory and to load it when needed.

`CTRL + F` to toggle fullscreen, `ESC` to quit.