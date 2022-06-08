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
// Design Name:    barrel_shifter_Nb                                          //
// Project Name:   riscv-jedro-1                                              //
// Language:       Verilog                                                    //
//                                                                            //
// Description:    A combinatorial circuit that performs shifting of 32-bit   //
//                 values. This is a logarithmic barrel shifter. 			  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module barrel_shifter_right_32b  (
    input  [32-1:0] in,
    input  [5-1:0] cntrl,	 // The amount to shift by
	input 		   arith,
    output [32-1:0] out
);

	wire [32-1:0] w1, w2, w3, w4, w5; // "inbetween" wires

	// Mux wire for if the shift should be arithmetic (and not logical)	
	wire mux_sign;

	assign mux_sign = (arith)?in[31]:(1'b0);
	
	// 1 bit shift right
	mux2x1 ins_1_0  (in[0],  in[1],  cntrl[0], w1[0]);	
	mux2x1 ins_1_1  (in[1],  in[2],  cntrl[0], w1[1]);	
	mux2x1 ins_1_2  (in[2],  in[3],  cntrl[0], w1[2]);	
	mux2x1 ins_1_3  (in[3],  in[4],  cntrl[0], w1[3]);	
	mux2x1 ins_1_4  (in[4],  in[5],  cntrl[0], w1[4]);	
	mux2x1 ins_1_5  (in[5],  in[6],  cntrl[0], w1[5]);	
	mux2x1 ins_1_6  (in[6],  in[7],  cntrl[0], w1[6]);	
	mux2x1 ins_1_7  (in[7],  in[8],  cntrl[0], w1[7]);	
	mux2x1 ins_1_8  (in[8],  in[9],  cntrl[0], w1[8]);	
	mux2x1 ins_1_9  (in[9],  in[10], cntrl[0], w1[9]);	   
	mux2x1 ins_1_10 (in[10], in[11], cntrl[0], w1[10]);	
	mux2x1 ins_1_11 (in[11], in[12], cntrl[0], w1[11]);	
	mux2x1 ins_1_12 (in[12], in[13], cntrl[0], w1[12]);	
	mux2x1 ins_1_13 (in[13], in[14], cntrl[0], w1[13]);	
	mux2x1 ins_1_14 (in[14], in[15], cntrl[0], w1[14]);	
	mux2x1 ins_1_15 (in[15], in[16], cntrl[0], w1[15]);	 
	mux2x1 ins_1_16 (in[16], in[17], cntrl[0], w1[16]);	
	mux2x1 ins_1_17 (in[17], in[18], cntrl[0], w1[17]);	
	mux2x1 ins_1_18 (in[18], in[19], cntrl[0], w1[18]);	
	mux2x1 ins_1_19 (in[19], in[20], cntrl[0], w1[19]);	
	mux2x1 ins_1_20 (in[20], in[21], cntrl[0], w1[20]);	
	mux2x1 ins_1_21 (in[21], in[22], cntrl[0], w1[21]);	
	mux2x1 ins_1_22 (in[22], in[23], cntrl[0], w1[22]);	
	mux2x1 ins_1_23 (in[23], in[24], cntrl[0], w1[23]);	
	mux2x1 ins_1_24 (in[24], in[25], cntrl[0], w1[24]);	
	mux2x1 ins_1_25 (in[25], in[26], cntrl[0], w1[25]);	
	mux2x1 ins_1_26 (in[26], in[27], cntrl[0], w1[26]);	
	mux2x1 ins_1_27 (in[27], in[28], cntrl[0], w1[27]);	
	mux2x1 ins_1_28 (in[28], in[29], cntrl[0], w1[28]);	
	mux2x1 ins_1_29 (in[29], in[30], cntrl[0], w1[29]);	
	mux2x1 ins_1_30 (in[30], in[31], cntrl[0], w1[30]);	
	mux2x1 ins_1_31 (in[31], mux_sign,  cntrl[0], w1[31]);	

	
	// 2 bit shift right
	mux2x1 ins_2_0  (w1[0],  w1[2],  cntrl[1], w2[0]);	
	mux2x1 ins_2_1  (w1[1],  w1[3],  cntrl[1], w2[1]);	
	mux2x1 ins_2_2  (w1[2],  w1[4],  cntrl[1], w2[2]);	
	mux2x1 ins_2_3  (w1[3],  w1[5],  cntrl[1], w2[3]);	
	mux2x1 ins_2_4  (w1[4],  w1[6],  cntrl[1], w2[4]);	
	mux2x1 ins_2_5  (w1[5],  w1[7],  cntrl[1], w2[5]);	
	mux2x1 ins_2_6  (w1[6],  w1[8],  cntrl[1], w2[6]);	
	mux2x1 ins_2_7  (w1[7],  w1[9],  cntrl[1], w2[7]);	
	mux2x1 ins_2_8  (w1[8],  w1[10], cntrl[1], w2[8]);	
	mux2x1 ins_2_9  (w1[9],  w1[11], cntrl[1], w2[9]);	   
	mux2x1 ins_2_10 (w1[10], w1[12], cntrl[1], w2[10]);	
	mux2x1 ins_2_11 (w1[11], w1[13], cntrl[1], w2[11]);	
	mux2x1 ins_2_12 (w1[12], w1[14], cntrl[1], w2[12]);	
	mux2x1 ins_2_13 (w1[13], w1[15], cntrl[1], w2[13]);	
	mux2x1 ins_2_14 (w1[14], w1[16], cntrl[1], w2[14]);	
	mux2x1 ins_2_15 (w1[15], w1[17], cntrl[1], w2[15]);	 
	mux2x1 ins_2_16 (w1[16], w1[18], cntrl[1], w2[16]);	
	mux2x1 ins_2_17 (w1[17], w1[19], cntrl[1], w2[17]);	
	mux2x1 ins_2_18 (w1[18], w1[20], cntrl[1], w2[18]);	
	mux2x1 ins_2_19 (w1[19], w1[21], cntrl[1], w2[19]);	
	mux2x1 ins_2_20 (w1[20], w1[22], cntrl[1], w2[20]);	
	mux2x1 ins_2_21 (w1[21], w1[23], cntrl[1], w2[21]);	
	mux2x1 ins_2_22 (w1[22], w1[24], cntrl[1], w2[22]);	
	mux2x1 ins_2_23 (w1[23], w1[25], cntrl[1], w2[23]);	
	mux2x1 ins_2_24 (w1[24], w1[26], cntrl[1], w2[24]);	
	mux2x1 ins_2_25 (w1[25], w1[27], cntrl[1], w2[25]);	
	mux2x1 ins_2_26 (w1[26], w1[28], cntrl[1], w2[26]);	
	mux2x1 ins_2_27 (w1[27], w1[29], cntrl[1], w2[27]);	
	mux2x1 ins_2_28 (w1[28], w1[30], cntrl[1], w2[28]);	
	mux2x1 ins_2_29 (w1[29], w1[31], cntrl[1], w2[29]);	
	mux2x1 ins_2_30 (w1[30], mux_sign,  cntrl[1], w2[30]);	
	mux2x1 ins_2_31 (w1[31], mux_sign,  cntrl[1], w2[31]);

		
	// 4 bit shift right
	mux2x1 ins_4_0  (w2[0],  w2[4],  cntrl[2], w3[0]);	
	mux2x1 ins_4_1  (w2[1],  w2[5],  cntrl[2], w3[1]);	
	mux2x1 ins_4_2  (w2[2],  w2[6],  cntrl[2], w3[2]);	
	mux2x1 ins_4_3  (w2[3],  w2[7],  cntrl[2], w3[3]);	
	mux2x1 ins_4_4  (w2[4],  w2[8],  cntrl[2], w3[4]);	
	mux2x1 ins_4_5  (w2[5],  w2[9],  cntrl[2], w3[5]);	
	mux2x1 ins_4_6  (w2[6],  w2[10], cntrl[2], w3[6]);	
	mux2x1 ins_4_7  (w2[7],  w2[11], cntrl[2], w3[7]);	
	mux2x1 ins_4_8  (w2[8],  w2[12], cntrl[2], w3[8]);	
	mux2x1 ins_4_9  (w2[9],  w2[13], cntrl[2], w3[9]);	   
	mux2x1 ins_4_10 (w2[10], w2[14], cntrl[2], w3[10]);	
	mux2x1 ins_4_11 (w2[11], w2[15], cntrl[2], w3[11]);	
	mux2x1 ins_4_12 (w2[12], w2[16], cntrl[2], w3[12]);	
	mux2x1 ins_4_13 (w2[13], w2[17], cntrl[2], w3[13]);	
	mux2x1 ins_4_14 (w2[14], w2[18], cntrl[2], w3[14]);	
	mux2x1 ins_4_15 (w2[15], w2[19], cntrl[2], w3[15]);	 
	mux2x1 ins_4_16 (w2[16], w2[20], cntrl[2], w3[16]);	
	mux2x1 ins_4_17 (w2[17], w2[21], cntrl[2], w3[17]);	
	mux2x1 ins_4_18 (w2[18], w2[22], cntrl[2], w3[18]);	
	mux2x1 ins_4_19 (w2[19], w2[23], cntrl[2], w3[19]);	
	mux2x1 ins_4_20 (w2[20], w2[24], cntrl[2], w3[20]);	
	mux2x1 ins_4_21 (w2[21], w2[25], cntrl[2], w3[21]);	
	mux2x1 ins_4_22 (w2[22], w2[26], cntrl[2], w3[22]);	
	mux2x1 ins_4_23 (w2[23], w2[27], cntrl[2], w3[23]);	
	mux2x1 ins_4_24 (w2[24], w2[28], cntrl[2], w3[24]);	
	mux2x1 ins_4_25 (w2[25], w2[29], cntrl[2], w3[25]);	
	mux2x1 ins_4_26 (w2[26], w2[30], cntrl[2], w3[26]);	
	mux2x1 ins_4_27 (w2[27], w2[31], cntrl[2], w3[27]);	
	mux2x1 ins_4_28 (w2[28], mux_sign,   cntrl[2], w3[28]);	
	mux2x1 ins_4_29 (w2[29], mux_sign,   cntrl[2], w3[29]);	
	mux2x1 ins_4_30 (w2[30], mux_sign,   cntrl[2], w3[30]);	
	mux2x1 ins_4_31 (w2[31], mux_sign,   cntrl[2], w3[31]);

	
	// 8 bit shift right
	mux2x1 ins_8_0  (w3[0],  w3[8],  cntrl[3], w4[0]);	
	mux2x1 ins_8_1  (w3[1],  w3[9],  cntrl[3], w4[1]);	
	mux2x1 ins_8_2  (w3[2],  w3[10], cntrl[3], w4[2]);	
	mux2x1 ins_8_3  (w3[3],  w3[11], cntrl[3], w4[3]);	
	mux2x1 ins_8_4  (w3[4],  w3[12], cntrl[3], w4[4]);	
	mux2x1 ins_8_5  (w3[5],  w3[13], cntrl[3], w4[5]);	
	mux2x1 ins_8_6  (w3[6],  w3[14], cntrl[3], w4[6]);	
	mux2x1 ins_8_7  (w3[7],  w3[15], cntrl[3], w4[7]);	
	mux2x1 ins_8_8  (w3[8],  w3[16], cntrl[3], w4[8]);	
	mux2x1 ins_8_9  (w3[9],  w3[17], cntrl[3], w4[9]);	   
	mux2x1 ins_8_10 (w3[10], w3[18], cntrl[3], w4[10]);	
	mux2x1 ins_8_11 (w3[11], w3[19], cntrl[3], w4[11]);	
	mux2x1 ins_8_12 (w3[12], w3[20], cntrl[3], w4[12]);	
	mux2x1 ins_8_13 (w3[13], w3[21], cntrl[3], w4[13]);	
	mux2x1 ins_8_14 (w3[14], w3[22], cntrl[3], w4[14]);	
	mux2x1 ins_8_15 (w3[15], w3[23], cntrl[3], w4[15]);	 
	mux2x1 ins_8_16 (w3[16], w3[24], cntrl[3], w4[16]);	
	mux2x1 ins_8_17 (w3[17], w3[25], cntrl[3], w4[17]);	
	mux2x1 ins_8_18 (w3[18], w3[26], cntrl[3], w4[18]);	
	mux2x1 ins_8_19 (w3[19], w3[27], cntrl[3], w4[19]);	
	mux2x1 ins_8_20 (w3[20], w3[28], cntrl[3], w4[20]);	
	mux2x1 ins_8_21 (w3[21], w3[29], cntrl[3], w4[21]);	
	mux2x1 ins_8_22 (w3[22], w3[30], cntrl[3], w4[22]);	
	mux2x1 ins_8_23 (w3[23], w3[31], cntrl[3], w4[23]);	
	mux2x1 ins_8_24 (w3[24], mux_sign,   cntrl[3], w4[24]);	
	mux2x1 ins_8_25 (w3[25], mux_sign,   cntrl[3], w4[25]);	
	mux2x1 ins_8_26 (w3[26], mux_sign,   cntrl[3], w4[26]);	
	mux2x1 ins_8_27 (w3[27], mux_sign,   cntrl[3], w4[27]);	
	mux2x1 ins_8_28 (w3[28], mux_sign,   cntrl[3], w4[28]);	
	mux2x1 ins_8_29 (w3[29], mux_sign,   cntrl[3], w4[29]);	
	mux2x1 ins_8_30 (w3[30], mux_sign,   cntrl[3], w4[30]);	
	mux2x1 ins_8_31 (w3[31], mux_sign,   cntrl[3], w4[31]);	

	
	// 16 bit shift right
	mux2x1 ins_16_0  (w4[0],  w4[16], cntrl[4], w5[0]);	
	mux2x1 ins_16_1  (w4[1],  w4[17], cntrl[4], w5[1]);	
	mux2x1 ins_16_2  (w4[2],  w4[18], cntrl[4], w5[2]);	
	mux2x1 ins_16_3  (w4[3],  w4[19], cntrl[4], w5[3]);	
	mux2x1 ins_16_4  (w4[4],  w4[20], cntrl[4], w5[4]);	
	mux2x1 ins_16_5  (w4[5],  w4[21], cntrl[4], w5[5]);	
	mux2x1 ins_16_6  (w4[6],  w4[22], cntrl[4], w5[6]);	
	mux2x1 ins_16_7  (w4[7],  w4[23], cntrl[4], w5[7]);	
	mux2x1 ins_16_8  (w4[8],  w4[24], cntrl[4], w5[8]);	
	mux2x1 ins_16_9  (w4[9],  w4[25], cntrl[4], w5[9]);	   
	mux2x1 ins_16_10 (w4[10], w4[26], cntrl[4], w5[10]);	
	mux2x1 ins_16_11 (w4[11], w4[27], cntrl[4], w5[11]);	
	mux2x1 ins_16_12 (w4[12], w4[28], cntrl[4], w5[12]);	
	mux2x1 ins_16_13 (w4[13], w4[29], cntrl[4], w5[13]);	
	mux2x1 ins_16_14 (w4[14], w4[30], cntrl[4], w5[14]);	
	mux2x1 ins_16_15 (w4[15], w4[31], cntrl[4], w5[15]);	 
	mux2x1 ins_16_16 (w4[16], mux_sign,   cntrl[4], w5[16]);	
	mux2x1 ins_16_17 (w4[17], mux_sign,   cntrl[4], w5[17]);	
	mux2x1 ins_16_18 (w4[18], mux_sign,   cntrl[4], w5[18]);	
	mux2x1 ins_16_19 (w4[19], mux_sign,   cntrl[4], w5[19]);	
	mux2x1 ins_16_20 (w4[20], mux_sign,   cntrl[4], w5[20]);	
	mux2x1 ins_16_21 (w4[21], mux_sign,   cntrl[4], w5[21]);	
	mux2x1 ins_16_22 (w4[22], mux_sign,   cntrl[4], w5[22]);	
	mux2x1 ins_16_23 (w4[23], mux_sign,   cntrl[4], w5[23]);	
	mux2x1 ins_16_24 (w4[24], mux_sign,   cntrl[4], w5[24]);	
	mux2x1 ins_16_25 (w4[25], mux_sign,   cntrl[4], w5[25]);	
	mux2x1 ins_16_26 (w4[26], mux_sign,   cntrl[4], w5[26]);	
	mux2x1 ins_16_27 (w4[27], mux_sign,   cntrl[4], w5[27]);	
	mux2x1 ins_16_28 (w4[28], mux_sign,   cntrl[4], w5[28]);	
	mux2x1 ins_16_29 (w4[29], mux_sign,   cntrl[4], w5[29]);	
	mux2x1 ins_16_30 (w4[30], mux_sign,   cntrl[4], w5[30]);	
	mux2x1 ins_16_31 (w4[31], mux_sign,   cntrl[4], w5[31]);

	assign out = w5;
	
endmodule


