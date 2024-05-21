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
    output new_isr,
	 output last_isr_jmp
    );
	 
// Keeps track of if the next M1 cycle will be the beginning of a new instruction
reg new_isr_r = 0;

// Is the last opcode byte read decoding into a JUMP instruction?
reg last_isr_jmp_r = 0;

// The next byte read will be the end of a multi-byte instruction
reg force_next_isr = 1;

assign new_isr = new_isr_r;
assign last_isr_jmp = last_isr_jmp_r;

always @(posedge m1_n)
begin
	last_isr_jmp_r = 0;
	if (force_next_isr) begin
		// Currently executing a BIT or MISC instruction
		new_isr_r = 1;
		force_next_isr = 0;
	end
	else if (data == 8'hCB || data == 8'hED) begin
		// Prefix for BIT or MISC instruction
		new_isr_r = 0;
		force_next_isr = 1;
	end
	else if (data == 8'hDD || data == 8'hED) begin
		// IX or IY instruction
		new_isr_r = 0;
		force_next_isr = 0;
	end
	else begin
		// Normal instruction
		new_isr_r = 1;
		force_next_isr = 0;
		if (data == 8'hC3)
			last_isr_jmp_r = 1;
	end
end

endmodule
