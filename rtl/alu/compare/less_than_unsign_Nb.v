////////////////////////////////////////////////////////////////////////////////                                          
// SPDX-FileCopyrightText: 2022, Jure Vreca                                   //                                          
//                                                                            //                                          
// Licenseunder the Apache License, Version 2.0(the "License");               //                                          
// you maynot use this file except in compliance with the License.            //                                           
// You may obtain a copy of the License at                                    //                                          
//                                                                            //                                          
//      http://www.apache.org/licenses/LICENSE-2.0                            //                                          
//                                                                            //                                          
// Unless required by applicable law or agreed to in writing, software        //                                          
// distributed under the License is distributed on an "AS IS" BASIS,          //                                          
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   //                                          
// See the License for the specific language governing permissions and        //                                          
// limitations under the License.                                             //                                          
// SPDX-License-Identifier: Apache-2.0                                        //                                          
// SPDX-FileContributor: Jure Vreca <jurevreca12@gmail.com>                   //                                          
////////////////////////////////////////////////////////////////////////////////      
////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jure Vreča - jurevreca12@gmail.com                       //
//                                                                            //
//                                                                            //
//                                                                            //
// Design Name:    less_than_unsign_Nb                                        //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    The module checks if a is less than b (a < b).             //
//                 This is for unsigned binary numbers.                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module less_than_unsign_Nb #(parameter N = 32) (
	input  [N-1:0] a,
	input  [N-1:0] b,
	output [N-1:0] r
);

wire [N-1:0] w0 = ~( a ^ b ); // check bits for equality
wire [N-1:0] w1 =  ( ~a & b ); // check if a is less than b  (i.e. a is zero and b is 1)
wire [N-1:0] w2;

assign w2[0] = w1[0];
assign r = { {N-1{1'b0}} , w2[N-1]};

genvar i;
generate 
	for (i = 1; i < N; i = i + 1) begin
        assign w2[i] = w1[i] | ( w0[i] & w2[i-1] );
    end
endgenerate

endmodule
