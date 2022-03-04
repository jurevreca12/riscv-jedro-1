// A basic test of the sra instruction.
`timescale 1ns/1ps

module jedro_1_sra_tb();
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 32;

  logic clk;
  logic rstn;
  
  int i;
  
  ram_read_io #(.ADDR_WIDTH(ADDR_WIDTH), 
                .DATA_WIDTH(DATA_WIDTH)) instr_mem_if();

  ram_rw_io data_mem_if();


  jedro_1_top dut(.clk_i       (clk),
                  .rstn_i      (rstn),
                  .instr_mem_if(instr_mem_if.MASTER),
                  .data_mem_if (data_mem_if.MASTER)
                );

  rams_init_file_wrap #(.MEM_INIT_FILE("jedro_1_sra_tb.mem")) rom_mem (.clk_i(clk),
                                                                       .rom_if(instr_mem_if));
  // Handle the clock signal
  always #1 clk = ~clk;

  initial begin
  clk <= 1'b0;
  rstn <= 1'b0;
  repeat (3) @ (posedge clk);
  rstn <= 1'b1;

  while (i < 32 && dut.decoder_inst.illegal_instr_ro == 0) begin
    @(posedge clk);
    i++;
  end
  repeat (3) @ (posedge clk); // finish instructions in the pipeline

  assert (dut.regfile_inst.regfile[31] == 1) 
  else $display("ERROR: After executing jedro_1_sra_tb.mem the value in register 31 should be 1, not %d.", 
                $signed(dut.regfile_inst.regfile[31]));

  assert (dut.regfile_inst.regfile[30] == 32'b11111111_11111111_11111111_11111111) 
  else $display("ERROR: After executing jedro_1_sra_tb.mem the value in register 30 should be -1, not %d.", 
                $signed(dut.regfile_inst.regfile[30]));

  $finish;
  end

endmodule : jedro_1_sra_tb
