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
	 input virtual_enabled,
	 output trap_state,

	 output nmi_n,

	 output capture_address

    );




// Flip-flop to keep track of if a trap is currently happening 

reg trap_state_r;

// Is there a trap pending?
reg trap_pending_r;


// Capture latch
reg capture_latch_r;

assign trap_state = trap_state_r;



always @(posedge m1_n)

begin

	

end



endmodule

