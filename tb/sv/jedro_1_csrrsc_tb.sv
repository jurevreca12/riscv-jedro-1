// A basic test of the csrrs and csrrc instructions.
`timescale 1ns/1ps

module jedro_1_csrrsc_tb();
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

  rams_init_file_wrap #(.MEM_INIT_FILE("jedro_1_csrrsc_tb.mem")) rom_mem (.clk_i(clk),
                                                                         .rom_if(instr_mem_if));
  // Handle the clock signal
  always #1 clk = ~clk;

  initial begin
  clk <= 1'b0;
  rstn <= 1'b0;
  repeat (3) @ (posedge clk);
  rstn <= 1'b1;
  dut.csr_inst.csr_mscratch_n = 3;

  while (i < 64) begin
    @(posedge clk);
    i++;
  end

  assert (dut.regfile_inst.regfile[1] == 32'h55C) 
  else $display("ERROR: After executing jedro_1_csrrsc_tb.mem the value in register 1 should be 0x55C, not %d.", 
                $signed(dut.regfile_inst.regfile[1]));
  
  assert (dut.regfile_inst.regfile[2] == 7) 
  else $display("ERROR: After executing jedro_1_csrrsc_tb.mem the value in register 2 should be 7, not %d.", 
                $signed(dut.regfile_inst.regfile[2]));

  assert (dut.regfile_inst.regfile[3] == 32'h55C) 
  else $display("ERROR: After executing jedro_1_csrrsc_tb.mem the value in register 3 should be 0x55C, not %d.", 
                $signed(dut.regfile_inst.regfile[3]));
  
  assert (dut.csr_inst.csr_mscratch_r == 32'h55F) 
  else $display("ERROR: After executing jedro_1_csrrsc_tb.mem the value in csr mscratch reg should be 0x55F, not %d.", 
                $signed(dut.csr_inst.csr_mscratch_r));
                              
  assert (dut.csr_inst.csr_mcause_r == 32'h558) 
  else $display("ERROR: After executing jedro_1_csrrsc_tb.mem the value in csr mcause reg should be 0x558, not %d.", 
                $signed(dut.csr_inst.csr_mcause_r));

  $finish;
  end

endmodule : jedro_1_csrrsc_tb