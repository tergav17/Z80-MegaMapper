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
	 input ignore_next_isr,
    output new_isr,
    output last_isr_untrap,
    output io_direction
    );
    
// Keeps track of if the next M1 cycle will be the beginning of a new instruction
reg new_isr_r = 0;

// Is the last opcode byte read decoding into a JUMP instruction?
reg last_isr_untrap_r = 0;

// The next byte read will be the end of a multi-byte instruction
reg force_next_isr = 1;

// Keep track of if the opcode was IX / IY
reg last_opcode_index_r = 0;

// Keeps track of the direction of the current I/O instruction
reg io_direction_r = 0;

// Keeps track of if an instruction is MISC
reg next_isr_misc = 0;

assign new_isr = new_isr_r;
assign last_isr_untrap = last_isr_untrap_r;
assign io_direction = io_direction_r;

always @(posedge m1_n)
begin

	// If the CPU is doing an IN or OUT instruction, lets try to find what direction it's going
	// We don't care what this value is if we aren't doing an I/O instruction
	// 0 = OUT
	// 1 = IN
	if (data[7:4] == 4'hD)
		io_direction_r <= data[3];
	else
		io_direction_r <= !data[0];

	last_isr_untrap_r <= 0;
	if (!ignore_next_isr) begin
		if (force_next_isr) begin
			// Currently executing a BIT or MISC instruction
			new_isr_r <= 1;
			force_next_isr <= 0;
			last_opcode_index_r <= 0;
			if (data == 8'h45) begin
				last_isr_untrap_r <= 1;
			end
		end
		else if (data == 8'hCB || data == 8'hED) begin
			// Prefix for BIT or MISC instruction
			if (!last_opcode_index_r) begin
				new_isr_r <= 0;
				force_next_isr <= 1;
			end
			else begin
				new_isr_r <= 1;
				force_next_isr <= 0;
			end
			last_opcode_index_r <= 0;
			
			// Is it a MISC instruction
			if (data == 8'hED) begin
				next_isr_misc = 1;
			end
			else
				next_isr_misc = 0;
			end
		end
		else if (data == 8'hDD || data == 8'hFD) begin
			// IX or IY instruction
			new_isr_r <= 0;
			force_next_isr <= 0;
			last_opcode_index_r <= 1;
		end
		else begin
			// Normal instruction
			new_isr_r <= 1;
			force_next_isr <= 0;
			last_opcode_index_r <= 0;
		end
	end
	else begin
		// Reset next isr latch
		new_isr_r <= 0;
		force_next_isr <= 0;
	end
end

endmodule
