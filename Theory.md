# Theory of Operation

The MegaMapper board works by intercepting Z80 bus signals and suppressing them to the larger system if necessary. How and when the signals are intercepted depends on what mode the MegaMapper is set in. The first of these modes is “Real Mode”. In this state, all memory signals will be passed to the Z80, and I/O signals will not be remapped. The 16 bytes of MegaMapper I/O space is still exposed, however. The trap state will be forced on in this mode. This is the default state of the machine and allows for original software to run unchanged.

The second mode that the machine can operate in is “Virtual Mode”. In this mode, memory operations are intercepted and sent to the onboard static RAM banks. All I/O signals will also be routed through the mapper table. How memory is laid out depends on if the MegaMapper is in the “Trap” state. If the trap state is active (this is always true by default), then memory looks like this:

0000-7FFF: Underlying system memory map
8000-BFFF: Mapper Table (256 byte blocks repeating)
C000-FFFF: SRAM Bank 3


When the trap state is reset, the memory map becomes the following:

0000-3FFF: SRAM Bank 0
4000-7FFF: SRAM Bank 1
8000-BFFF: SRAM Bank 2
C000-FFFF: SRAM BANK 3
