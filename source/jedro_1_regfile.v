////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreca - jurevreca12@gmail.com                         //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_regfile                                            //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    The register file and its interface.                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module jedro_1_regfile
#(
	parameter	DATA_WIDTH = 32,
	parameter	ADDR_WIDTH = $clog2(DATA_WIDTH)
)
(
	input 						clk_i,
	input						rstn_i,

	// Write port A
	input 	[ADDR_WIDTH-1:0] 	wpa_addr_i,
	input 	[DATA_WIDTH-1:0]	wpa_data_i,
	input 						wpa_we_i,

	// Write port B
	input   [ADDR_WIDTH-1:0]	rpb_addr_i,
	output  [DATA_WIDTH-1:0]	rpb_data_o,

	// Write port C
	input	[ADDR_WIDTH-1:0]	rpc_addr_i,
	output	[DATA_WIDTH-1:0]	rpc_data_o
);

localparam NUM_REGISTERS = 2 ** (ADDR_WIDTH);

// Integer register file x0-x31
reg [DATA_WIDTH-1:0] reg_file [NUM_REGISTERS-1:0];


// Mux the appropriate register to the data_o line
assign rpb_data_o = reg_file[rpb_addr_i];
assign rpc_data_o = reg_file[rpc_addr_i];


// Register x0-x31 reset
genvar i;
for (i=0; i < NUM_REGISTERS; i=i+1) begin
always@(posedge clk_i)
begin
	if (rstn_i == 1'b0)	begin
			reg_file[i] <= 32'b0;
	end
end
end

// Write to the registers (register x0 should always be zero)
always@(posedge clk_i)
begin
	if (wpa_we_i == 1'b1 && rstn_i != 1'b0) begin
		if (wpa_addr_i != 0) begin
			reg_file[wpa_addr_i] <= wpa_data_i;
		end
	end
end


`ifdef COCOTB_SIM
initial begin
	$dumpfile("jedro_1_regfile.vcd");
	$dumpvars(0, jedro_1_regfile);
	#1;
end
`endif

endmodule

