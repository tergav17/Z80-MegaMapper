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
    input m1_n,
    input [7:0] addr,
    input reset_n,
    output iorq_sys_n,
    output mreq_sys_n
    );

wire [7:0] ctrl_register;

// Define activation condition for the mapper I/O space
wire mapper_io = !addr[7] && !addr[6] && addr[5] && !addr[4] && !iorq_n;

// Define activation condition for reading the instruction register
wire read_isr_en = mapper_io && !addr[3] && !addr[0];

// Define activation condition for writing the control register
wire write_ctrl_en = mapper_io && !addr[3] && addr[2]; 

// Create instance of register logic
registers reg_0(data, wr_n, rd_n, m1_n, 1'b1, read_isr_en, write_ctrl_en, reset_n, ctrl_register);

endmodule
