# [IBM PC/XT](https://en.wikipedia.org/wiki/IBM_Personal_Computer_XT) for [Xilinx Spartan 6](https://www.xilinx.com/products/silicon-devices/fpga/spartan-6.html)

PCXT port for Xilinx Spartan 6 Family FPGAs by [@spark2k06](https://github.com/spark2k06/).

## Description

The purpose of this core is to implement a PCXT as reliable as possible. For this purpose, the [MCL86 core](https://github.com/MicroCoreLabs/Projects/tree/master/MCL86) from [@MicroCoreLabs](https://github.com/MicroCoreLabs/) and [KFPC-XT](https://github.com/kitune-san/KFPC-XT) from [@kitune-san](https://github.com/kitune-san) are used.

The [Graphics Gremlin project](https://github.com/schlae/graphics-gremlin) from TubeTimeUS ([@schlae](https://github.com/schlae)) has also been integrated in this first stage.

[JTOPL](https://github.com/jotego/jtopl) by Jose Tejada (@topapate) was integrated for AdLib sound.

An SN76489AN Compatible Implementation (Tandy Sound) written in VHDL was also integrated - Copyright (c) 2005, 2006, [Arnim Laeuger](https://github.com/devsaurus) (arnim.laeuger@gmx.net)

## Models powered by Spartan 6

* ZXUno & ZXUnCore 512Kb: PCXT, CGA and PC Speaker.
* ZXUno & ZXUnCore 2Mb: PCXT, Tandy 1000, CGA and PC speaker.
* ZXDos 512Kb: PCXT, CGA, Adlib, Tandy Sound, PC Speaker.
* ZXDos 1Mb, NGo: PCXT, Tandy 1000, CGA, Adlib, Tandy Sound, PC Speaker.
* ZXDos+, UnoXT, UnoXT2: PCXT, Tandy 1000, CGA, Adlib, Tandy Sound, PC Speaker.

ZXUno & ZXUnCore are powered by Spartan XC6SLX9.

ZXDos, NGo are powered by Spartan XC6SLX16.

UnoXT, UnoXT2 & ZXDos+ are powered by Spartan XC6SLX25.

## To-do list and challenges

* Improved implementation of 8-bit IDE module
* UART & Mouse implementation
* Other implementations

## Developers

Any contribution and pull request, please carry it out on the prerelease branch. Periodically they will be reviewed, moved and merged into the main branch, together with the corresponding release.

Thank you!
