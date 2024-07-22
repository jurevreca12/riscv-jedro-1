// A basic test of the and instruction.
`timescale 1ns/1ps

module jedro_1_and_tb();
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 32;

  logic clk;
  logic rstn;
  logic [31:0] iaddr;
  logic [31:0] idata;
  int i;

  logic [31:0] rdata;
  logic ack;
  logic err;
  logic [3:0] we;
  logic stb;
  logic [31:0] addr;
  logic [31:0] wdata;
 
  bytewrite_ram_wrap data_mem (.clk_i  (clk),                                                                           
                               .rstn_i (rstn),
			       .rdata(rdata),
                               .ack(ack),
                               .err(err),
                               .we(we),
                               .stb(stb),
                               .addr(addr),
                               .wdata(wdata));
                                                                          
  jedro_1_top dut(.clk_i       (clk),
                  .rstn_i      (rstn),
		  .iram_addr   (iaddr),
                  .iram_rdata  (iram_rdata),
                  .dram_we     (we),
                  .dram_stb    (stb),
                  .dram_addr   (addr),
                  .dram_wdata  (wdata),
                  .dram_rdata  (rdata),
                  .dram_ack    (ack),
                  .dram_err    (err));

  rams_init_file_wrap #(.MEM_INIT_FILE("jedro_1_and_tb.mem")) rom_mem (.clk_i(clk),
								       .addr_i(iaddr),
								       .rdata_o(idata));
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

  assert (dut.regfile_inst.regfile[1] == 1 + 2 + 4) 
  else $display("ERROR: After executing jedro_1_and_tb.mem the value in register 1 should be 14, not %d.", 
                dut.regfile_inst.regfile[1]);
  
  assert (dut.regfile_inst.regfile[2] == 1 + 2 + 4) 
  else $display("ERROR: After executing jedro_1_and_tb.mem the value in register 2 should be 14, not %d.", 
                dut.regfile_inst.regfile[2]);

  $finish;
  end

endmodule : jedro_1_and_tb
