 // parameterized tri-port 1 write-side and 2 read-side used in datapool
 `timescale 1ns/1ns
 // For use in SYMPL 32-Bit Multi-Thread, Multi-Processing GP-GPU-Compute Engine
 // Author:  Jerry D. Harthcock
 // Version:  1.204  Dec. 12, 2015
 // Copyright (C) 2014-2015.  All rights reserved without prejudice.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                   SYMPL 32-Bit Multi-Thread, Multi-Processing GP-GPU-Compute Engine                           //
//                              Evaluation and Product Development License                                       //
//                                                                                                               //
// Provided that you comply with all the terms and conditions set forth herein, Jerry D. Harthcock ("licensor"), //
// the original author and exclusive copyright owner of the SYMPL 32-Bit Multi-Thread, Multi-Processing GP-GPU-  //
// Compute Engine Verilog RTL IP core family and instruction-set architecture ("this IP"), hereby grants to      //
// recipient of this IP ("licensee"), a world-wide, paid-up, non-exclusive license to use this IP for the        //
// non-commercial purposes of evaluation, education, and development of end products and related development     //
// tools only. For a license to use this IP in commercial products intended for sale, license, lease or any      //
// other form of barter, contact licensor at:  SYMPL.gpu@gmail.com                                               //
//                                                                                                               //
// Any customization, modification, or derivative work of this IP must include an exact copy of this license     //
// and original copyright notice at the very top of each source file and derived netlist, and, in the case of    //
// binaries, a printed copy of this license and/or a text format copy in a separate file distributed with said   //
// netlists or binary files having the file name, "LICENSE.txt".  You, the licensee, also agree not to remove    //
// any copyright notices from any source file covered under this Evaluation and Product Development License.     //
//                                                                                                               //
// THIS IP IS PROVIDED "AS IS".  LICENSOR DOES NOT WARRANT OR GUARANTEE THAT YOUR USE OF THIS IP WILL NOT        //
// INFRINGE THE RIGHTS OF OTHERS OR THAT IT IS SUITABLE OR FIT FOR ANY PURPOSE AND THAT YOU, THE LICENSEE, AGREE //
// TO HOLD LICENSOR HARMLESS FROM ANY CLAIM BROUGHT BY YOU OR ANY THIRD PARTY FOR YOUR SUCH USE.                 //                               
//                                                                                                               //
// Licensor reserves all his rights without prejudice, including, but in no way limited to, the right to change  //
// or modify the terms and conditions of this Evaluation and Product Development License anytime without notice  //
// of any kind to anyone. By using this IP for any purpose, you agree to all the terms and conditions set forth  //
// in this Evaluation and Product Development License.                                                           //
//                                                                                                               //
// This Evaluation and Product Development License does not include the right to sell products that incorporate  //
// this IP or any IP derived from this IP.  If you would like to obtain such a license, please contact Licensor. //                                                                                            //
//                                                                                                               //
// Licensor can be contacted at:  SYMPL.gpu@gmail.com                                                            //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module RAM_tdp_dpool #(parameter ADDRS_WIDTH = 10, parameter DATA_WIDTH = 32) (
    CLKA,
    CLKB,
    wrenA,
    wraddrsA,
    wrdataA,
    wrenB,
    wraddrsB,
    wrdataB,
    rdenA,
    rdaddrsA,
    rddataA,
    rdenB,
    rdaddrsB,
    rddataB);    

input  CLKA;
input  CLKB;
input  wrenA;
input  wrenB;
input  [ADDRS_WIDTH-1:0] wraddrsA;
input  [DATA_WIDTH-1:0] wrdataA;
input  [ADDRS_WIDTH-1:0] wraddrsB;
input  [DATA_WIDTH-1:0] wrdataB;
input  rdenA;
input  [ADDRS_WIDTH-1:0] rdaddrsA;
output [DATA_WIDTH-1:0] rddataA;
input  rdenB;    
input  [ADDRS_WIDTH-1:0] rdaddrsB;
output [DATA_WIDTH-1:0] rddataB;


reg    [DATA_WIDTH-1:0] triportRAM[(2**ADDRS_WIDTH)-1:0];

wire [ADDRS_WIDTH-1:0] addrsA;
wire [ADDRS_WIDTH-1:0] addrsB;

assign addrsA = wrenA ? wraddrsA : rdaddrsA;
assign addrsB = wrenB ? wraddrsB : rdaddrsB;

integer i;

initial begin
   i = 2**ADDRS_WIDTH;
   while(i) 
    begin
        triportRAM[i] = 0;
        i = i - 1;
    end
    triportRAM[0] = 0;
    rddataA = 32'h0000_0000;
    rddataB = 32'h0000_0000;
end

reg [DATA_WIDTH-1:0] rddataA;
reg [DATA_WIDTH-1:0] rddataB;

always @(posedge CLKA) begin
    if (wrenA || rdenA) begin
        if (wrenA) begin
            triportRAM[addrsA] <= wrdataA;
            rddataA <= triportRAM[addrsA];
        end
        else rddataA <= triportRAM[addrsA];    
    end
end
always @(posedge CLKB) begin
    if (wrenB || rdenB) begin
        if (wrenB) begin
            triportRAM[addrsB] <= wrdataB;
            rddataB <= triportRAM[addrsB];
        end
        else rddataB <= triportRAM[addrsB];    
    end
end

endmodule    