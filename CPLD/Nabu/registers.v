`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Gavin Tersteeg 
// 
// Create Date:    01:21:04 05/16/2024 
// Design Name: 
// Module Name:    registers 
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
module registers(
    inout [7:0] data,
    input wr_n,
    input rd_n,
    input m1_n,
    input record_isr_en,
    input read_isr_en,
    input write_ctrl_en,
    input reset_n,
    output [7:0] ctrl_out
    );

// Define control and instruction registers
reg[7:0] ctrl_reg;
reg[7:0] isr_reg;

// Logic for reading the control register
assign ctrl_out = ctrl_reg;

// Logic for controlling the contents of the control register
always @(posedge wr_n or negedge reset_n)
begin
   if (!reset_n)
      ctrl_reg = 8'b00000000;
   else if (write_ctrl_en)
      ctrl_reg = data;
end

// Logic for reading the output register
assign data = (!rd_n && read_isr_en) ? isr_reg : 8'bZZZZZZZZ;

// Logic for controlling the contents of the instruction registers
always @(posedge m1_n)
begin
   if (record_isr_en)
      isr_reg = data;
end

endmodule
