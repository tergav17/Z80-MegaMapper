# Theory of Operation

The MegaMapper board works by intercepting Z80 bus signals and suppressing them to the larger system if necessary. How and when the signals are intercepted depends on what mode the MegaMapper is set in. The first of these modes is “Real Mode”. In this state, all memory signals will be passed to the Z80, and I/O signals will not be remapped. The 8 bytes of MegaMapper I/O space are still exposed, however. The trap state will be forced on in this mode. This is the default state of the machine and allows for original software to run unchanged.

The second mode that the machine can operate in is “Virtual Mode”. In this mode, memory operations are intercepted and sent to the onboard static RAM banks. All I/O signals will also be routed through the mapper table. How memory is laid out depends on if the MegaMapper is in the “Trap” state. If the trap state is active (this is always true by default), then memory looks like this:

- 0000-7FFF: Underlying System Memory
- 8000-BFFF: Mapper Table (256 byte blocks repeating)
- C000-FFFF: Virtual RAM Bank 3

When the trap state is reset, the memory map becomes the following:

- 0000-3FFF: Virtual RAM Bank 0
- 4000-7FFF: Virtual RAM Bank 1
- 8000-BFFF: Virtual RAM Bank 2
- C000-FFFF: Virtual RAM BANK 3

Each bank of virtual RAM can be mapped to one of up to 256 banks of onboard static RAM. The maximum amount of RAM that can be addressed this way is 4MB.

To exit out of the trap state, a `RETN` instruction must be executed (0xED45). The instruction will be executed normally, though the stack pointer will be constrained to a 4K window of memory. On the downward edge of the next M1 cycle, the trap state will be reset and memory access will be routed appropriately. It is important to ensure that the "I/O Trap Occured" latch is reset when doing this. Should this latch be set, only a single instruction will be executed before another trap occurs. The "I/O Trap Occured" latch can be reset by accessing the I/O trap vector while in the trap state.

When interrupt intercept mode is enabled and the trap state is reset, maskable interrupts are not directly sent to the CPU. They are instead used to generate traps, and the control register is used to directly manipulate the state of the maskable interrupt when untrapped.

There are a number of conditions that can start the trap response. These include a maskable interrupt during intercept mode (sampled at the beginning of an M1 cycle), or an I/O instruction accessing the trap address. When an I/O trap occurs, the “I/O Trap Occured” latch will be set. This condition will be sampled on the downward edge of the next M1 cycle of a new instruction. The status of the maskable interrupt pin will also be sampled if intercept mode in enabled. If either of these are asserted, then a trap will occur. It should be noted that both of these conditions are tied to the non-maskable interrupt pin. With a trap state is detected on the downward edge of the new M1 cycle, the trap state latch is set. Additionally, the “Address Capture” flip-flop will be set, forcing the memory accesses of the next M1 cycle to be constrained to a 4K window of memory (On the NABU, this is 0x7000-0x7FFF). This allows the return address to be recovered by the driver regardless of where the stack pointer is located in memory. The pushing of the return address also will not effect the contents of virtual memory. This flip-flop will be reset at the start of the next M1 cycle.

When not in trap mode, the MegaMapper will record the fetched byte at the end of every M1 cycle. This is so the hypervisor can mock I/O instructions as needed. Since only knowledge about what IN/OUT instruction has been executed is needed, the entire instruction is not encoded. Specifically, bit 2 is replaced with the “I/O Trap Occured” latch.

# Memory Map

The MegaMapper occupies 8 bytes of I/O space. On the NABU, this ranges from 0x30-0x37. Registers are as follows:

Memory map:
- 0x30 W: Bank register #0
- 0x31 W: Bank register #1
- 0x32 W: Bank register #2
- 0x33 W: Bank register #3
- 0x34 W: Control Register
- 0x30 R: Instruction Register
- 0x32 R: Address Low Register
- 0x33 R: Address High Register
- 0x37 R/W: Trap Vector

Bank register bits:
- 0-7: Bank select (128 total)
- 8: Write protect page

Instruct register bits
- 0-1: Last instruction opcode
- 2: I/O trap occured latch
- 3-7: Last instruction opcode

Control register bits:
- 0: Enable virtual mode
- 1: Translation table program direction (0 = OUT, 1 = IN)
- 2: IRQ intercept mode
- 3: Force maskable interrupt (intercept mode only)
- 4: N/A
- 5: N/A
- 6: N/A
- 7: N/A



