// The test used to simulate the core with the riscof test framework.
`timescale 1ns/1ps

module jedro_1_riscof_tb();
  parameter DATA_WIDTH     = 32;
  parameter ADDR_WIDTH     = 32;
  parameter MEM_SIZE_WORDS = 1 << 19;
  parameter TIMEOUT        = 1000000;
 
  localparam SIG_START_ADDR_CELLNUM = MEM_SIZE_WORDS - 1;
  localparam SIG_END_ADDR_CELLNUM   = MEM_SIZE_WORDS - 2;
  localparam HALT_COND_CELLNUM      = MEM_SIZE_WORDS - 3;
   
  logic clk;
  logic rstn;
  
  int i;
  int j;

  // Instruction interface  
  ram_read_io #(.ADDR_WIDTH(ADDR_WIDTH), 
                .DATA_WIDTH(DATA_WIDTH)) instr_mem_if();

  rams_init_file_wrap #(.MEM_SIZE_WORDS(MEM_SIZE_WORDS),
                        .MEM_INIT_FILE("out.hex")) rom_mem (.clk_i(clk),
                                                            .rom_if(instr_mem_if.SLAVE));

  // Data interface
  ram_rw_io data_mem_if();
  rams_init_file_rw_wrap #(.MEM_SIZE_WORDS(MEM_SIZE_WORDS),
                           .MEM_INIT_FILE("out.hex")) data_mem (.clk_i (clk),
                                                                .ram_if(data_mem_if.SLAVE));


  jedro_1_top dut(.clk_i       (clk),
                  .rstn_i      (rstn),
                  .instr_mem_if(instr_mem_if.MASTER),
                  .data_mem_if (data_mem_if.MASTER)
                );


  // Handle the clock signal
  always #1 clk = ~clk;


  integer sig_file, start_addr, end_addr;
  initial begin
  clk <= 1'b0;
  rstn <= 1'b0;
  repeat (3) @ (posedge clk);
  rstn <= 1'b1;
 
  while (i < TIMEOUT) begin
    @(posedge clk);
    i++;
  end

  // get stard and end address of the signature region
  start_addr = data_mem.ram_memory.RAM[SIG_START_ADDR_CELLNUM];
  end_addr   = data_mem.ram_memory.RAM[SIG_END_ADDR_CELLNUM];

  sig_file = $fopen("dut.signature", "w");
  for (j=start_addr; j < end_addr; j=j+4) begin
    $fwrite(sig_file, "%h\n", data_mem.ram_memory.RAM[j>>2]);
  end
  $fclose(sig_file);
  $finish;
  end

endmodule : jedro_1_riscof_tb
