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
    input iorq_n,
    input m1_n,
	 input record_isr,
	 input reset_n
    );

// Define control and instruction registers
reg[7:0] ctrl_reg;
reg[7:0] isr_reg;

always @(posedge wr_n or negedge reset_n)
begin
	if (!reset_n)
		ctrl_reg = 8'b00000000;
	else if (!iorq_n)
		ctrl_reg = data;
end

always @(posedge m1_n)
begin
	if (record_isr)
		isr_reg = data;
end

endmodule
