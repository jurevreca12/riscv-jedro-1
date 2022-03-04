// A basic test of the instruction-address-misaligned exception behavior
`timescale 1ns/1ps

module jedro_1_misaligned_jmp_tb();
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

  rams_init_file_wrap #(.MEM_INIT_FILE("jedro_1_misaligned_jmp_tb.mem")) rom_mem (.clk_i(clk),
                                                                                  .rom_if(instr_mem_if));
  // Handle the clock signal
  always #1 clk = ~clk;

  initial begin
  clk <= 1'b0;
  rstn <= 1'b0;
  repeat (3) @ (posedge clk);
  rstn <= 1'b1;

  while (i < 64) begin
    @(posedge clk);
    i++;
  end

  assert (dut.regfile_inst.regfile[1] == 14) 
  else $display("ERROR: After executing jedro_1_misaligned_jmp_tb.mem the value in register 1 should be 14, not %d.", 
                $signed(dut.regfile_inst.regfile[1]));

  assert (dut.regfile_inst.regfile[2] == 33) 
  else $display("ERROR: After executing jedro_1_misaligned_jmp_tb.mem the value in register 2 should be 33, not %d.", 
                $signed(dut.regfile_inst.regfile[2]));

  $finish;
  end

endmodule : jedro_1_misaligned_jmp_tb