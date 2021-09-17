////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreča - jurevreca12@gmail.com                         //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_ifu	                                              //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    The instruction fetch unit for SPROM memory with           //
//				   a single cycle read delay.								  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import jedro_1_defines::*;
import interfaces::if_ram_1way;

module jedro_1_ifu 
(
	input	clk_i,
	input	rstn_i,

	input 	get_next_instr_i,	// A signal that specifys that we can get the next isntruction (controlled by the cores FSM)
	output	next_instr_lock_o, // Indicates that the next instruction is not ready to be processed TODO
	input		jmp_instr_i,		// specify that we encountered a jump instruction and the program counter should be changed to jmp_address_i
	
	// This address comes from the ALU (actually it comes from a mux after the ALU)
	input	[`DATA_WIDTH-1:0] jmp_address_i,		// The address to jump to, after we had encountered a jump instruction
	
	// Interface to the ROM memory
  if_ram_1way.MASTER      if_inst_mem,

	// Interface to the decoder
	output [`DATA_WIDTH-1:0] cinstr_o		// The current instruction (to be decoded)
);

logic [`DATA_WIDTH-1:0] pc_r;

// COMBINATIAL LOGIC
// The output address just follows pc_r
assign addr_o = pc_r;
assign rsta_o = ~rstn_i;

// SEQUENTIAL LOGIC
// Synchronous reset
always @(posedge clk_i) begin
	if (rstn_i == 1'b0) begin
		pc_r <= `BOOT_ADDR;
		en_o <= 1'b1;
		cinstr_o <= 0;
		next_instr_lock_o <= 0;
	end
	else begin
		cinstr_o <= data_i;
		if (get_next_instr_i == 1'b1) begin	
			if (jmp_instr_i == 1'b1) begin
				pc_r <= jmp_address_i;
			end
			else begin
				pc_r <= pc_r + 4;
			end 
		end
	end	
end

endmodule




