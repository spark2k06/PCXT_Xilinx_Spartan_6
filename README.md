# [IBM PC/XT](https://en.wikipedia.org/wiki/IBM_Personal_Computer_XT) for [ZXUno FPGA](https://zxuno.speccy.org/)

PCXT port for ZXUno by [@spark2k06](https://github.com/spark2k06/).

Discussion and evolution of the core in the following retrowiki forum thread:

...

## Description

The purpose of this core is to implement a PCXT as reliable as possible. For this purpose, the [MCL86 core](https://github.com/MicroCoreLabs/Projects/tree/master/MCL86) from [@MicroCoreLabs](https://github.com/MicroCoreLabs/) and [KFPC-XT](https://github.com/kitune-san/KFPC-XT) from [@kitune-san](https://github.com/kitune-san) are used.

The [Graphics Gremlin project](https://github.com/schlae/graphics-gremlin) from TubeTimeUS ([@schlae](https://github.com/schlae)) has also been integrated in this first stage.

[JTOPL](https://github.com/jotego/jtopl) by Jose Tejada (@topapate) was integrated for AdLib sound.

An SN76489AN Compatible Implementation (Tandy Sound) written in VHDL was also integrated - Copyright (c) 2005, 2006, [Arnim Laeuger](https://github.com/devsaurus) (arnim.laeuger@gmx.net)

## Notice

The current status of the project is very preliminary... at the moment, only a diagnostic ROM is being used for testing purposes.

Some modules are not connected, such as the keyboard or the sound system. The core is unstable, outside of this diagnostic environment, normal real PCXT BIOSes do not boot.

There are timing issues, especially in relation to the VRAM which is currently located in the SRAM, in the current state and with a solution in place for the dual port requirement, the core only runs at 14.318MHz. Small changes such as adding a speaker signal for the speaker to sound can cause artifacts on the screen.

## To-do list and challenges

* Refactor Graphics Gremlin module, the new KFPC-XT system will make this refactor possible.
* 8-bit IDE module implementation
* Floppy implementation
* Addition of other modules

## Developers

Any contribution and pull request, please carry it out on the prerelease branch. Periodically they will be reviewed, moved and merged into the main branch, together with the corresponding release.

Thank you!
