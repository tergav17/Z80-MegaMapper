`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////

// Company: 

// Engineer: Gavin Tersteeg

// 

// Create Date:    02:45:57 05/17/2024 

// Design Name: 

// Module Name:    assembly 

// Project Name: 

// Target Devices: 

// Tool versions: 

// Description: 

//

// Dependencies: 

//

// Revision: 

// Revision 0.01 - File Created

// Additional Comments: 

//

//////////////////////////////////////////////////////////////////////////////////

module assembly(

    inout [7:0] data,

    input wr_n,

    input rd_n,

    input iorq_n,

    input mreq_n,
	 input irq_sys_n,

    input m1_n,

	 input refresh_n,

    input [2:0] lo_addr,
	 input [1:0] hi_addr,
	 input io_enable,

    input reset_n,

    output iorq_sys_n,

    output mreq_sys_n,

	 output irq_n,
	 output nmi_n,
	 output translate_addr,
	 output capture_address

    );



wire [7:0] ctrl_register;



// Define activation condition for the mapper I/O space

wire mapper_io = io_enable && !iorq_n;



// Define activation condition for reading the instruction register

wire read_isr_en = mapper_io && !lo_addr[2] && !lo_addr[1] && !lo_addr[0];



// Define activation condition for writing the control register

wire write_ctrl_en = mapper_io && lo_addr[2] && !lo_addr[1]; 


// Keep track of instruction state going into mode logic
wire new_isr;
wire last_isr_jmp;

// Define control register bits
wire virtual_enable = ctrl_register[0];
wire force_irq = ctrl_register[1];

// Suppress I/O when in mapper I/O space

assign iorq_sys_n = iorq_n || mapper_io;

// Supress memory accesses when external memory or writing to the translation table
// If a refresh operation occures or virtualization is turned off, no remapping should be done
wire xmem_in_range = trap_state ? hi_addr[0] && hi_addr[1] : 1;
wire xmem_n = (refresh_n && virtual_enable) ? !xmem_in_range : 1;

assign mreq_sys_n = (refresh_n && virtual_enable) ? 0 : mreq_n;

// Trap state used to control how interrupts work
wire trap_state;

// When the trap state is reset, maskable interrupts should be controlled by the control register
assign irq_n = trap_state ? !force_irq : irq_sys_n;

// Address translations should always be done if virtualization is enabled
// Unless a memory I/O access in incoming, of course
assign translate_addr = virtual_enable && mreq_n;

// I/O violations need to be readable from the instruction register
wire io_violation_occured;


// Create instance of register logic

registers reg_0(data, wr_n, rd_n, m1_n, 1'b1, read_isr_en, write_ctrl_en, reset_n, ctrl_register);



// Create instance of opcode detection logic

opcode opcode_0(data, m1_n, new_isr, last_isr_jmp);

// Create instance of mode logic
modes modes_0(mapper_io && lo_addr[2] && lo_addr[1], irq_sys_n, m1_n, new_isr, last_isr_jmp, virtual_enable, io_violation_occured, trap_state, nmi_n, capture_address);



endmodule

