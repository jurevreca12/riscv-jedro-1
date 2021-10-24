// Wraps the block ram instantiation module with a system verilog interface
//
`timescale 1ns/1ps

module rams_init_file_wrap
#(
    parameter MEM_INIT_FILE =""
)
(
  input clk,
  ram_read_io.SLAVE rom_if
);


  rams_init_file #(.MEM_INIT_FILE(MEM_INIT_FILE)) rom_memory (
                          .clk(clk), 
                          .we(1'b0), 
                          .addr(rom_if.addr[rom_if.ADDR_WIDTH-1:0]), 
                          .din(32'b0), 
                          .dout(rom_if.rdata[rom_if.DATA_WIDTH-1:0])
                        );

endmodule

