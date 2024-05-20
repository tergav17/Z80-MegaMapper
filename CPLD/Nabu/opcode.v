`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Gavin Tersteegl
// 
// Create Date:    04:10:42 05/18/2024 
// Design Name: 
// Module Name:    opcode 
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
module opcode(
    input [7:0] data,
    input m1_n,
    output at_isr_end,
	 output is_retn
    );
	 
reg last_was_isr = 0;
reg last_isr_was_retn = 0;
reg force_next_isr = 1;

assign at_isr_end = last_was_isr;
assign is_retn = last_isr_was_retn;

always @(posedge m1_n)
begin
	last_isr_was_retn = 0;
	if (force_next_isr) begin
		// Currently executing a BIT or MISC instruction
		last_was_isr = 1;
		force_next_isr = 0;
		
		if (data == 8'h45)
			last_isr_was_retn = 1;
	end
	else if (data == 8'hCB || data == 8'hED) begin
		// Prefix for BIT or MISC instruction
		last_was_isr = 0;
		force_next_isr = 1;
	end
	else if (data == 8'hDD || data == 8'hED) begin
		// IX or IY instruction
		last_was_isr = 0;
		force_next_isr = 0;
	end
	else begin
		// Normal instruction
		last_was_isr = 1;
		force_next_isr = 0;
	end
end

endmodule
