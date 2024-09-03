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
    input io_violation,
    input irq_sys_n,
    input m1_n,
    input new_isr,
    input last_isr_untrap,
    input virtual_enabled,
	 input irq_intercept,
	 input rd_n,
	 input iorq_n,
    output io_violation_occured,
    output trap_state,
    output nmi_n,
    output capture_latch,
	 output irq_sync
    );


// Flip-flop to keep track of if a trap is currently happening 
reg trap_state_r = 0;

// Has an I/O address violation occured?
reg io_violation_occured_r = 0;

// Address capture latch
reg capture_latch_r = 0;

// Interrupt sync
reg irq_sync_r = 0;

// Was this I/O operation the result of an IRQ response?
reg doing_irq_response_r = 0;

// Assign registers to outputs
assign trap_state = trap_state_r;
assign irq_sync = irq_sync_r;
assign capture_latch = capture_latch_r;
assign io_violation_occured = io_violation_occured_r;

// A trap can said to be pending when either there is an interrupt waiting, or an I/O violation has been observed
wire trap_pending = io_violation_occured_r || (!irq_sync_r && irq_intercept);

// A NMI should only be asserted when trap state is reset
assign nmi_n = !trap_pending || trap_state_r || !m1_n;

// Keep track of if an I/O request started during an M1 clock cycle
// If so, this is definately an IRQ request instead of an I/O operations
always @(negedge iorq_n)
begin
	doing_irq_response_r = !m1_n;
end

assign io_trap_event = io_violation && !doing_irq_response_r;

// If an I/O violation occures while trap mode is reset, then set the flag
// Otherwise, an I/O violation during trap mode will reset the flag
always @(posedge io_trap_event)
begin
		io_violation_occured_r = !trap_state_r;
end

always @(negedge m1_n)
begin
	if (rd_n) begin
		// If the capture latch has been enabled for a M1 cycle, disable it
		if (capture_latch_r) begin
			capture_latch_r <= 0;
		end

		if (!trap_state_r) begin
			// Trap must always be set when virtualization is off
			if (!virtual_enabled)
				trap_state_r <= 1;
			
			// If there is a trap pending, update the state
			if (trap_pending && new_isr) begin
				trap_state_r <= 1;
				capture_latch_r <= 1;
			end 
		end 
		else begin
			// Trap can be ended by executing a jump instruction
			if (last_isr_untrap && virtual_enabled) begin
				trap_state_r <= 0;
			end
		end
	end
end

always @(posedge m1_n)
begin
   // Interrupt gets updated on the positive edge of every M1 cycle
   // May slow down interrupt response by an instruction or two, but gets rid of a lot of edge cases
   irq_sync_r <= irq_sys_n;
end

endmodule
