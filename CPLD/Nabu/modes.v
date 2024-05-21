`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:41:31 05/19/2024 
// Design Name: 
// Module Name:    modes 
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
module modes(
    input trap_condition,
    input irq_n,
    input m1_n,
    input new_isr,
	 input last_isr_jmp,
    output virtual_mode,
	 output nmi_n,
	 output override_address
    );


reg virtual_mode_r = 0;

always @(posedge m1_n)
begin
	
end

endmodule
