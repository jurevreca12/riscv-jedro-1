////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreča - jurevreca12@gmail.com                         //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    jedro_1_alu                                                //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    The module checks for equality of two signed or unsigned   //
//                 signals.                                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module equality_Nb #(parameter N = 32) (
	input  [N-1:0] a,
	input  [N-1:0] b,
	output         r
);

wire [N-1:0] w;

assign w = a ^ b;
assign r = ~( |w );

endmodule

