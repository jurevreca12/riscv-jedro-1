////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreča - jurevreca12@gmail.com                       //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_ifu                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    The instruction fetch unit for SPROM memory with           //
//                 a single cycle read delay. The jmp_instr_i should only be  //
//                 asserted for a single clock cycle (for every jmp instr).   //
//                                                                            //
//                                      _________                             //
//                 ________             |       |                             //
//                 |       |------------| pc[0] |                             //
//                 |       |            |_______|                             //
//                 |  RAM  |                                                  //
//                 |       |            ____________                          //
//                 |       |            |          |                          //
//                 |       |------------| instr_ro |---                       //
//                 |_______|            |__________|                          //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

import jedro_1_defines::*;

module jedro_1_ifu 
(
  input logic clk_i,
  input logic rstn_i,

  input logic jmp_instr_i,     // Specifes that we encountered a jump instruction and the program 
                               // counter should be changed to jmp_address_i.
  
  input logic [DATA_WIDTH-1:0] jmp_address_i,    // The address to jump to, after we had encountered a jump instruction.

  // Interface to the decoder
  output logic [DATA_WIDTH-1:0] instr_ro,         // The current instruction (to be decoded)
  output logic [DATA_WIDTH-1:0] instr_addr_ro,    // Used by instructons that calculate on the PC.
  output logic                  instr_valid_ro,
  input  logic                  decoder_ready_i, // Decoder ready to accept new instruction
  
  // Interface to the ROM memory
  ram_read_io.MASTER            instr_mem_if
);
localparam INSTR_SHIFTREG_DEPTH = 3;

logic [DATA_WIDTH-1:0] pc_shift_reg [INSTR_SHIFTREG_DEPTH-1:0];
logic [INSTR_SHIFTREG_DEPTH-1:0] instr_valid_shiftreg;
logic [DATA_WIDTH-1:0] stall_save_reg;
logic is_1cycle_after_stall; // are we one cycle after the stall happened?


/***************************************
* PROGRAM COUNTER LOGIC
***************************************/
assign instr_mem_if.addr = pc_shift_reg[0]; // The output address just follows pc_shift_reg[0]
assign instr_addr_ro = pc_shift_reg[2];

always_ff @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
     pc_shift_reg[0] <= BOOT_ADDR;
     pc_shift_reg[1] <= BOOT_ADDR;
     pc_shift_reg[2] <= BOOT_ADDR;
  end
  else begin
    if (decoder_ready_i == 1'b1) begin
        if (jmp_instr_i == 1'b1) begin
            pc_shift_reg[0] <= jmp_address_i;
        end
        else begin
            pc_shift_reg[0] <= pc_shift_reg[0] + 4;
        end
        pc_shift_reg[1] <= pc_shift_reg[0];
        pc_shift_reg[2] <= pc_shift_reg[1];
    end
    else begin
      pc_shift_reg <= pc_shift_reg;
    end
  end
end


/***************************************
* VALID SIGNAL GENERATION
***************************************/
assign instr_valid_ro = instr_valid_shiftreg[INSTR_SHIFTREG_DEPTH-1];

always_ff @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    instr_valid_shiftreg <= INSTR_SHIFTREG_DEPTH'('b001);
  end
  else begin
    if (decoder_ready_i == 1'b1) begin
        instr_valid_shiftreg <= instr_valid_shiftreg << 1;
        if (jmp_instr_i == 1'b1) begin
          instr_valid_shiftreg[0] <= 1'b0;
        end
        else begin
          instr_valid_shiftreg[0] <= 1'b1;
        end
    end
    else begin
      instr_valid_shiftreg <= instr_valid_shiftreg;
    end
  end
end


/***************************************
* READING LOGIC
***************************************/
always_ff @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    instr_ro <= 32'b000000000001_00000_000_00000_0010011; // we reset to the NOP operationi
  end
  else begin
    if (decoder_ready_i == 1'b1 && instr_valid_shiftreg[0] == 1'b1) begin
        if (is_1cycle_after_stall == 1'b0) begin
            instr_ro <= instr_mem_if.rdata;
        end
        else begin
            instr_ro <= stall_save_reg;
        end
    end
    else begin
        instr_ro <= instr_ro;
    end
  end
end


/***************************************
* STALL SAVE LOGIC
***************************************/
always_ff @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        stall_save_reg <= 32'b000000000001_00000_000_00000_0010011;
    end
    else begin
        stall_save_reg <= instr_mem_if.rdata;
    end
end

// After stall signal
always_ff @(posedge clk_i) begin
    if (rstn_i == 1'b0) begin
        is_1cycle_after_stall <= 1'b0;
    end
    else begin
        if (decoder_ready_i == 1'b0) begin
            is_1cycle_after_stall <= 1'b1;
        end
        else begin
            is_1cycle_after_stall <= 1'b0;
        end
    end
end


endmodule : jedro_1_ifu
