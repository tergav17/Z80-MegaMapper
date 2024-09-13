# Z80 MegaMapper

![Assembled ZMM](https://github.com/tergav17/Z80-MegaMapper/blob/main/Resources/IMG_1.jpg)

The Z80 MegaMapper (ZMM) is designed to enhance the ability of existing retro computers. This is done by interposing the Z80 CPU and intercepting certain signals. The current version of the MegaMapper provides the following enhancements:

- An additional 512 KB of static RAM, expandable up to 2 MB.
- Simple memory management, allowing the 4 independently selectable memory banks. Banks can also be write protected.
- Virtual machine mode, supporting “transparent” traps that do not depend on a specific stack pointer location.
- Fully programmable I/O space in virtual mode, allowing device addresses to be translated between the virtual and physical address space.
- I/O trap vector allowing any I/O instruction to be emulated by software if needed.
- Software controllable interrupts, allowing the maskable interrupt to be fully controlled by the real mode hypervisor.

The expanded memory is fairly self explanatory, but the other features may require a bit of explanation. The goal of the MegaMapper is to allow a Z80 machine to support “virtual machines”. These machines, with the help of a software hypervisor, can be made to seamlessly run software from other computer architectures. A single machine can act as an MSX, Colecovision, SG-1000, ZX81, Heathkit H8, TRS-80 Model II, TI-83, etc… simply by changing what hypervisor software is running. Additionally, virtual machines can be debugged in real time, to the point of being single-steppable. 

This is different from emulation as fundamentally everything is still executing on bare hardware. It provides vast software compatibility while still scratching the “retro hardware” itch that makes emulators simply not as fun (personally). In theory, this same type of device could have been built in the 80s with off-the-shelf components. All of the heavy lifting is still done by the ~3.5 Mhz Z80 processor.

Admittedly, emulation can always provide better results than a janky virtualization set up like this. This is more of a “Because I Can” project than anything else. 

# Current Issues

The Z80 data bus buffer currently doesn't work properly due to IM2-related shenanigans. The system works fine without it, so it may be omitted in a future revision.

At the moment, there is no way to maintain IFF2 contents during a trap. This is fine for systems that don't need an NMI, but can cause interrupt issues to those that do. It should be possible to add a status bit that keeps trick of if IFF1 and IFF2 are supposed to be equal, and work backwards from there.

# Installation

The ZMM is designed to slot directly into where the Z80 plugs into the mainboard of the host computer. Everything runs on +5V, so no additional jumpers are needed.

![ZMM Installed in a Nabu](https://github.com/tergav17/Z80-MegaMapper/blob/main/Resources/IMG_2.jpg)

# Limitations

One of the major design limitations of the ZMM is the fact that no provisions have been made for memory mapped I/O. Video RAM can crudely be accomplished by periodically scanning parts of memory and updating the VDP accordingly. This is very inefficient, especially the bigger the VRAM section gets. The size of the bankable sections is also limited to 16 KB, anything smaller will have to be emulated by manually copying sections of memory.

# BOM

| Quantity | Reference  | Part          | Link |
| -------- | ---------- | ------------- | ---- |
|        1 | U2         | 74LS32        |      |
|        2 | U3, U4     | 74LS670       |      |
|        1 | U5         | HM6116        |      |
|        3 | U6..8      | 74LS157       |      |
|        1 | U9         | 74LS244       |      |
|        2 | U10, U11   | 74LS374       |      |
|        1 | U12        | 74LS85        |      |
|        1 | U13        | XC9536PC44    |      |
|        1 | U14        | 74LS139       |      |
|      1-4 | U15..18    | AS6C4008      |      |
|        1 | U19        | 74LS245       |      |
|       19 | C1..19     | 0.1 uF C      |      |
|        1 | C20        | 100 uF        |      |
