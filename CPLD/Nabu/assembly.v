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
    output trans_addr,
    output trap_addr_wr_n,
    output trap_addr_rd_n,
    output bank_wr_n,
    output capture_addr,
    output xmem_sel_n,
    output trans_wr_n,
    output trans_direction

    );



wire [2:0] ctrl_register;



// Define activation condition for the mapper I/O space

wire mapper_io = io_enable && !iorq_n;



// Define activation condition for reading the instruction register

wire read_isr_en = mapper_io && !lo_addr[2] && !lo_addr[1] && !lo_addr[0];



// Define activation condition for writing the control register

wire write_ctrl_en = mapper_io && lo_addr[2] && !lo_addr[1]; 

// Define I/O violation condition
wire io_violation_cond = mapper_io && lo_addr[2] && lo_addr[1];

// Keep track of instruction state going into mode logic
wire new_isr;
wire last_isr_untrap;

// Trap state used to control how interrupts work
wire trap_state;

// What is the direction of the I/O instruction we may be execution
wire io_direction;

// Define control register bits
wire virtual_enable = ctrl_register[0];
wire force_irq = ctrl_register[1];
wire set_trans_direction = ctrl_register[2];

// We should capture the current "real" address everytime there is an I/O violation
assign trap_addr_wr_n = !io_violation_cond;

// For when we want to read either the high or low trap address
assign trap_addr_rd_n = !(mapper_io && !lo_addr[2] && lo_addr[1]) || rd_n;

// For wehn we want to write to the bank registers
assign bank_wr_n = !(mapper_io && !lo_addr[2]) || wr_n;

// Suppress I/O when in mapper I/O space

assign iorq_sys_n = iorq_n || mapper_io;

// Supress memory accesses when external memory or writing to the translation table
// If a refresh operation occures or virtualization is turned off, no remapping should be done
wire mreq_override_cond = (trap_state ? hi_addr[1] : 1) && refresh_n && virtual_enable;

assign mreq_sys_n = mreq_override_cond || mreq_n;
assign trans_wr_n = !mreq_override_cond || mreq_n || !(trap_state && !hi_addr[0]) || wr_n;
assign xmem_sel_n = !mreq_override_cond || mreq_n || (trap_state && !hi_addr[0]);

// When the trap state is reset, maskable interrupts should be controlled by the control register
assign irq_n = trap_state ? irq_sys_n : !force_irq;

// Address translations should always be done if virtualization is enabled
// Unless a memory I/O access in incoming, of course
assign trans_addr = virtual_enable && mreq_n && refresh_n;

// If we are doing a memory request, the direction page of the translation
// table will be determined by the control register. Otherwise it is controlled
// on whenever we are doing an input or an output instruction
assign trans_direction = mreq_n ? io_direction : set_trans_direction;

// I/O violations need to be readable from the instruction register
wire io_violation_occured;


// Create instance of register logic

registers reg_0(data, wr_n, rd_n, m1_n, !trap_state, read_isr_en, write_ctrl_en, reset_n, io_violation_occured, ctrl_register);



// Create instance of opcode detection logic

opcode opcode_0(data, m1_n, capture_addr, new_isr, last_isr_untrap, io_direction);

// Create instance of mode logic
modes modes_0(io_violation_cond, irq_sys_n, m1_n, new_isr, last_isr_untrap, virtual_enable, io_violation_occured, trap_state, nmi_n, capture_addr);



endmodule

