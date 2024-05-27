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

    input [7:0] addr,

    input reset_n,
	 input clk,

    output iorq_sys_n,

    output mreq_sys_n,

	 output irq_n,
	 output nmi_n,
	 output trap_state,
	 output capture_address

    );



wire [7:0] ctrl_register;



// Define activation condition for the mapper I/O space

wire mapper_io = !addr[7] && !addr[6] && addr[5] && addr[4] && !iorq_n;



// Define activation condition for reading the instruction register

wire read_isr_en = mapper_io && !addr[3] && !addr[0];



// Define activation condition for writing the control register

wire write_ctrl_en = mapper_io && !addr[3] && addr[2]; 


// Keep track of instruction state going into mode logic
wire new_isr;
wire last_isr_jmp;

// Suppress I/O when in mapper I/O space

assign iorq_sys_n = iorq_n || mapper_io;

// Supress memory accesses depending on virtualization and trap state

assign mreq_sys_n = mreq_n;


// Create instance of register logic

registers reg_0(data, wr_n, rd_n, m1_n, 1'b1, read_isr_en, write_ctrl_en, reset_n, ctrl_register);



// Create instance of opcode detection logic

opcode opcode_0(data, m1_n, new_isr, last_isr_jmp);

// Create instance of mode logic
modes modes_0(mapper_io && addr[3], irq_sys_n, m1_n, new_isr, last_isr_jmp, ctrl_register[0], clk, trap_state, nmi_n, irq_n, capture_address);



endmodule

