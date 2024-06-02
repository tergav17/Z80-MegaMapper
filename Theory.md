# Theory of Operation

The MegaMapper board works by intercepting Z80 bus signals and suppressing them to the larger system if necessary. How and when the signals are intercepted depends on what mode the MegaMapper is set in. The first of these modes is “Real Mode”. In this state, all memory signals will be passed to the Z80, and I/O signals will not be remapped. The 16 bytes of MegaMapper I/O space is still exposed, however. The trap state will be forced on in this mode. This is the default state of the machine and allows for original software to run unchanged.

The second mode that the machine can operate in is “Virtual Mode”. In this mode, memory operations are intercepted and sent to the onboard static RAM banks. All I/O signals will also be routed through the mapper table. How memory is laid out depends on if the MegaMapper is in the “Trap” state. If the trap state is active (this is always true by default), then memory looks like this:

0000-7FFF: Underlying System Memory
8000-BFFF: Mapper Table (256 byte blocks repeating)
C000-FFFF: Virtual RAM Bank 3


When the trap state is reset, the memory map becomes the following:

0000-3FFF: Virtual RAM Bank 0
4000-7FFF: Virtual RAM Bank 1
8000-BFFF: Virtual RAM Bank 2
C000-FFFF: Virtual RAM BANK 3

Each bank of virtual RAM can be mapped to one of up to 256 banks of onboard static RAM. The maximum amount of RAM that can be addressed this way is 4MB.

To exit out of the trap state, an unconditional jump instruction must be executed (0xC3). The instruction will be executed normally. On the downward edge of the next M1 cycle, the trap state will be reset and memory access will be routed as such.

In the trap state, maskable interrupts are not directly sent to the CPU. They are instead used to generate traps, and a register is used to manipulate the state of the maskable interrupt during virtual mode directly.

There are a number of conditions that can start the trap response. These include a maskable interrupt (sampled at the beginning of an M1 cycle), or an I/O instruction accessing the trap address. When an I/O trap occurs, the “I/O Trap Occured” latch will be set. This condition will be sampled on the downward edge of the next M1 cycle of a new instruction. The status of the maskable interrupt pin will also be sampled. If either of these are asserted, then a trap will occur. It should be noted that both of these conditions are tied to the non-maskable interrupt pin. With a trap state detected on the downward edge of the new M1 cycle, the trap state is set. Additionally, the “Address Capture” flip-flop will be set, forcing the memory accesses of the next M1 cycle to be constrained to a 4K window of memory. This allows the return address to be recovered by the driver regardless of where the stack pointer is located in memory. This flip-flop will be reset when the trap flip-flop is also reset.


When not in trap mode, the MegaMapper will record the fetched byte at the end of every M1 cycle. This is so the hypervisor can mock I/O instructions as needed. Since only knowledge about what IN/OUT instruction has been executed is needed, the entire instruction is not encoded. Specifically, bit 1 is not included. This bit is replaced with the “I/O Trap Occured” flip-flop.

# Memory Map

The MegaMapper occupies 16 bytes of I/O space. On the NABU, this ranges from 0x30-0x3F. Registers are as follows:

0x30 W: Bank register #0
0x31 W: Bank register #1
0x32 W: Bank register #2
0x33 W: Bank register #3
0x34 W: Control Register
0x30 R: Instruction Register
0x32 R: Address Low Register
0x33 R: Address High Register
0x38 R/W: Trap Vector

Control register bits:
0: Enable virtual mode
1: ?
2: ?
3: ?
4: Protect bank 0
5: Protect bank 1
6: Protect bank 2
7: Protect bank 3
