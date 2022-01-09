// Wraps the block ram instantiation module with a system verilog interface
//
`timescale 1ns/1ps

module rams_init_file_rw_wrap
#(
    parameter MEM_INIT_FILE="",
    parameter MEM_SIZE=2**12
)
(
  input clk_i,
  ram_rw_io.SLAVE ram_if
);


  bytewrite_ram_1b #(.SIZE(MEM_SIZE),
                     .MEM_INIT_FILE(MEM_INIT_FILE)) ram_memory (
                          .clk(clk_i), 
                          .we(ram_if.we[3:0]), 
                          .addr(ram_if.addr[ram_if.ADDR_WIDTH-1:0]), 
                          .di(ram_if.wdata[ram_if.ADDR_WIDTH-1:0]), 
                          .dout(ram_if.rdata[ram_if.DATA_WIDTH-1:0])
                        );

endmodule

