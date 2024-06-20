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
    input last_isr_jmp,
    input virtual_enabled,
    output io_violation_occured,
    output trap_state,
    output nmi_n,
    output capture_address
    );


// Flip-flop to keep track of if a trap is currently happening 
reg trap_state_r;

// Has an I/O address violation occured?
reg io_violation_occured_r;

// Address capture latch
reg capture_latch_r;

// Interrupt sync
reg irq_sync_r;

// Assign registers to outputs
assign trap_state = trap_state_r;
assign capture_address = capture_latch_r;
assign io_violation_occured = io_violation_occured_r;

// A trap can said to be pending when either there is an interrupt waiting, or a I/O violation has been observed
wire trap_pending = io_violation_occured_r || !irq_sync_r;

// An NMI should only be asserted what trap state is reset
assign nmi_n = !trap_pending || trap_state_r;

// If an I/O violation occures while trap mode is reset, the set the flag
// Otherwise, an I/O violation during trap mode will reset the flag
always @(negedge io_violation)
begin
   io_violation_occured_r = !trap_state_r;
end

always @(negedge m1_n)
begin
   // If the capture latch has been enabled for a M1 cycle, disable it
   if (capture_latch_r)
      capture_latch_r = 0;

   if (!trap_state_r) begin
      // Trap must always be set when virtualization is off
      if (!virtual_enabled)
         trap_state_r = 1;
      
      // If there is a trap pending, update the state
      if (trap_pending && new_isr) begin
         trap_state_r = 1;
         capture_latch_r = 1;
      end 
   end 
   else begin
      // Trap can be ended by executing a jump instruction
      if (last_isr_jmp && virtual_enabled)
         trap_state_r = 0;
   end
end

always @(posedge m1_n)
begin
   // Interrupt gets updated on the positive edge of every M1 cycle
   // May slow down interrupt response by an instruction or two, but gets rid of a lot of edge cases
   irq_sync_r = irq_sys_n;
end

endmodule
