// core.v
`timescale 1ns/100ps
// Shader core SYMPL 32-Bit Multi-Thread, Multi-Processing GP-GPU-Compute Engine
// Author:  Jerry D. Harthcock
// Version:  3.06  Dec. 12, 2015
// July 11, 2015
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

module core (
         PC,
         P_DATAi,
         ROM_4k_rddataA,     
         rdprog,
         srcA,
         srcB,
         dest_q2, 
         pre_PC,        
         prvt_2k_rddataA,  
         prvt_2k_rddataB,
         resultout,
         rdsrcA,
         rdsrcB,
         rdconstA,         
         wrcycl,
         CLK,
         RESET_IN,
         tr3_done,
         tr2_done,
         tr1_done,
         tr0_done,
         newthreadq,
         thread_q2,
                                 
//         SWBRKdet,
         
         tr3_IRQ,
         tr2_IRQ,
         tr1_IRQ,
         tr0_IRQ
          );
          
output  [11:0] PC;
input   [31:0] P_DATAi;
input   [31:0] ROM_4k_rddataA;     
output         rdprog;
output  [13:0] srcA;
output  [13:0] srcB;

output  [13:0] dest_q2;

output  [11:0] pre_PC;
input   [31:0] prvt_2k_rddataA;  
input   [31:0] prvt_2k_rddataB;
output  [31:0] resultout;
output         rdsrcA;
output         rdsrcB;
output         rdconstA;
output         wrcycl;
input          CLK;
input          RESET_IN;
output         tr3_done;
output         tr2_done;
output         tr1_done;
output         tr0_done;
output [1:0]   newthreadq;
output [1:0]   thread_q2;
        
//output         SWBRKdet;

input          tr3_IRQ;
input          tr2_IRQ;
input          tr1_IRQ;
input          tr0_IRQ;
                                                                                                                                      
parameter THREAD3      =  2'b11;  //P_ADDRS[31:30] indicate active thread
parameter THREAD2      =  2'b10;  //P_ADDRS[31:30] indicate active thread
parameter THREAD1      =  2'b01;  //P_ADDRS[31:30] indicate active thread
parameter THREAD0      =  2'b00;  //P_ADDRS[31:30] indicate active thread

parameter AR3_ADDRS    = 14'h0073;
parameter AR2_ADDRS    = 14'h0072;
parameter AR1_ADDRS    = 14'h0071;
parameter AR0_ADDRS    = 14'h0070;
parameter PC_ADDRS     = 14'h006F;    //address of each PC in private memory
parameter PC_COPY      = 14'h006E;    //status register address for each thread
parameter ST_ADDRS     = 14'h006D;    //status register address for each thread
parameter SCHED_ADDRS  = 14'h006C;
parameter SCHEDCMP_ADDRS  = 14'h006B; //scheduler reload address
parameter CREG_ADDRS =   14'h006A;    // "C" register for FMA operator
parameter LPCNT1_ADDRS = 14'h0069;    //loop counter 1 address
parameter LPCNT0_ADDRS = 14'h0068;    //loop counter 0 address
parameter TIMER_ADDRS  = 14'h0067;
parameter QOS_ADDRS    = 14'h0066;    // FP quality of service address
parameter RPT_ADDRS    = 14'h0064;
parameter CAPT3_ADDRS  = 14'h0063;    //delayed alternate exception handling captured rounding mode, thread and PC
parameter CAPT2_ADDRS  = 14'h0062;    //delayed alternate exception handling captured srcB, srcA and corresponding FP exception code
parameter CAPT1_ADDRS  = 14'h0061;    //delayed alternate exception handling captured resultB
parameter CAPT0_ADDRS  = 14'h0060;    //delayed alternate exception handling captured resultA

parameter MOV_    = 4'b0000;      
parameter AND_    = 4'b0001;
parameter OR_     = 4'b0010;
parameter XOR_    = 4'b0011;
parameter BTB_    = 4'b0100;            //bit test and branch
parameter BCND_   = 4'b0100;            //branch on condition
parameter DBNZ_   = 4'b0100;            //decrement srcB and branch if result is not zero
parameter SHFT_   = 4'b0101;
parameter ADD_    = 4'b0110;
parameter ADDC_   = 4'b0111;
parameter SUB_    = 4'b1000;
parameter SUBB_   = 4'b1001;
parameter MUL_    = 4'b1010;
parameter RCP_    = 4'b1011;
parameter SIN_    = 4'b1100;
parameter COS_    = 4'b1101;
parameter TAN_    = 4'b1110;
parameter COT_    = 4'b1111;

parameter LEFT_  = 3'b000;
parameter LSL_   = 3'b001;
parameter ASL_   = 3'b010;
parameter ROL_   = 3'b011;
parameter RIGHT_ = 3'b100;
parameter LSR_   = 3'b101;
parameter ASR_   = 3'b110;
parameter ROR_   = 3'b111;          
 
// state 1 fetch
reg [1:0] thread_q1;
reg [11:0] pc_q1;
reg [1:0] constn_q1;         // 00 = no const lookup, 10 = srcA, 01 = srcB, 11 = immediate
reg [3:0] opcode_q1;
reg [13:0] srcA_q1;
reg [13:0] srcB_q1;
reg [7:0] OPdest_q1;
reg [7:0] OPsrcA_q1;
reg [7:0] OPsrcB_q1;

// state2 read
reg [1:0] thread_q2;
reg [11:0] pc_q2;
reg [3:0] opcode_q2;
reg [13:0] srcA_q2;
reg [13:0] srcB_q2;
reg [7:0] OPdest_q2;
reg [7:0] OPsrcA_q2;                                                              
          
reg [31:0] tr3_AR3;
reg [31:0] tr3_AR2;
reg [31:0] tr3_AR1;
reg [31:0] tr3_AR0;

reg [31:0] tr2_AR3;
reg [31:0] tr2_AR2;
reg [31:0] tr2_AR1;
reg [31:0] tr2_AR0;

reg [31:0] tr1_AR3;
reg [31:0] tr1_AR2;
reg [31:0] tr1_AR1;
reg [31:0] tr1_AR0;

reg [31:0] tr0_AR3;
reg [31:0] tr0_AR2;
reg [31:0] tr0_AR1;
reg [31:0] tr0_AR0;

reg [11:0] PC;
reg [11:0] tr3_PC;
reg [11:0] tr2_PC;
reg [11:0] tr1_PC;
reg [11:0] tr0_PC;

reg [11:0] tr3_PC_COPY;
reg [11:0] tr2_PC_COPY;
reg [11:0] tr1_PC_COPY;
reg [11:0] tr0_PC_COPY;

reg [19:0] tr3_timer;
reg [19:0] tr2_timer;
reg [19:0] tr1_timer;
reg [19:0] tr0_timer;

reg [19:0] tr3_timercmpr;
reg [19:0] tr2_timercmpr;
reg [19:0] tr1_timercmpr;
reg [19:0] tr0_timercmpr;

reg [7:0] tr3_underflow_QOS;   
reg [7:0] tr2_underflow_QOS;   
reg [7:0] tr1_underflow_QOS;   
reg [7:0] tr0_underflow_QOS;   

reg [7:0] tr3_overflow_QOS;
reg [7:0] tr2_overflow_QOS;
reg [7:0] tr1_overflow_QOS;
reg [7:0] tr0_overflow_QOS;

reg [7:0] tr3_divby0_QOS;
reg [7:0] tr2_divby0_QOS;
reg [7:0] tr1_divby0_QOS;
reg [7:0] tr0_divby0_QOS;

reg [7:0] tr3_invalid_QOS;
reg [7:0] tr2_invalid_QOS;
reg [7:0] tr1_invalid_QOS;
reg [7:0] tr0_invalid_QOS;

reg tr3_invalid_flag;
reg tr2_invalid_flag;
reg tr1_invalid_flag;
reg tr0_invalid_flag;
    
reg tr3_divby0_flag;
reg tr2_divby0_flag;
reg tr1_divby0_flag;
reg tr0_divby0_flag;
    
reg tr3_overflow_flag;
reg tr2_overflow_flag;
reg tr1_overflow_flag;                                                       
reg tr0_overflow_flag;                                                       
                                                                             
reg tr3_underflow_flag;                                                      
reg tr2_underflow_flag;                                                      
reg tr1_underflow_flag;                                                      
reg tr0_underflow_flag;                                                      
                                                                             
reg tr3_inexact_flag;                                                        
reg tr2_inexact_flag;                                                        
reg tr1_inexact_flag;
reg tr0_inexact_flag;
    
reg tr3_alt_inv_handl;
reg tr2_alt_inv_handl;
reg tr1_alt_inv_handl;
reg tr0_alt_inv_handl;
    
reg tr3_alt_div0_handl;
reg tr2_alt_div0_handl;
reg tr1_alt_div0_handl;
reg tr0_alt_div0_handl;
    
reg tr3_alt_ovfl_handl;
reg tr2_alt_ovfl_handl;
reg tr1_alt_ovfl_handl;
reg tr0_alt_ovfl_handl;
    
reg tr3_alt_unfl_handl;
reg tr2_alt_unfl_handl;
reg tr1_alt_unfl_handl;
reg tr0_alt_unfl_handl;

reg tr3_alt_nxact_handl;
reg tr2_alt_nxact_handl;
reg tr1_alt_nxact_handl;
reg tr0_alt_nxact_handl;

reg tr3_alt_del_nxact;
reg tr2_alt_del_nxact;
reg tr1_alt_del_nxact;
reg tr0_alt_del_nxact;

reg tr3_alt_del_unfl; 
reg tr2_alt_del_unfl; 
reg tr1_alt_del_unfl; 
reg tr0_alt_del_unfl; 

reg tr3_alt_del_ovfl; 
reg tr2_alt_del_ovfl; 
reg tr1_alt_del_ovfl; 
reg tr0_alt_del_ovfl; 

reg tr3_alt_del_div0; 
reg tr2_alt_del_div0; 
reg tr1_alt_del_div0; 
reg tr0_alt_del_div0; 

reg tr3_alt_del_inv;  
reg tr2_alt_del_inv;  
reg tr1_alt_del_inv;  
reg tr0_alt_del_inv;  

reg tr0_IRQ_IE;
reg tr1_IRQ_IE;
reg tr2_IRQ_IE;
reg tr3_IRQ_IE;

reg tr3_Z;
reg tr2_Z;
reg tr1_Z;
reg tr0_Z;

reg tr3_C;
reg tr2_C;
reg tr1_C;
reg tr0_C;

reg tr3_N;
reg tr2_N;
reg tr1_N;
reg tr0_N;

reg tr3_V;
reg tr2_V;
reg tr1_V;
reg tr0_V;

reg tr0_done;   
reg tr1_done;   
reg tr2_done;   
reg tr3_done;   
    
reg tr0_locked; 
reg tr1_locked; 
reg tr2_locked; 
reg tr3_locked; 

reg [31:0] scheduler;
reg [31:0] sched_cmp;
reg [3:0] sched_state;

reg [31:0] tr0_C_reg;
reg [31:0] tr1_C_reg;
reg [31:0] tr2_C_reg;
reg [31:0] tr3_C_reg;

reg [2:0] STATE;
wire [1:0] ACT_THREAD;

reg [1:0] pipe_flush_tr0;
reg [1:0] pipe_flush_tr1;
reg [1:0] pipe_flush_tr2;
reg [1:0] pipe_flush_tr3;

reg [31:0] wrsrcAdata;
reg [31:0] wrsrcBdata;
 
reg [31:0] resultout;
reg        Z_q2;
reg        C_q2;
reg        N_q2;
reg        V_q2;

//loop counters for DBNZ
reg [11:0] tr0_LPCNT0;
reg [11:0] tr0_LPCNT1;

reg [11:0] tr1_LPCNT0;
reg [11:0] tr1_LPCNT1;

reg [11:0] tr2_LPCNT0;
reg [11:0] tr2_LPCNT1;

reg [11:0] tr3_LPCNT0;
reg [11:0] tr3_LPCNT1;

reg [15:0] shiftbucket;
reg [31:0] rdSrcAdata;
reg [31:0] rdSrcBdata; 
reg [11:0] pre_PC;
reg [1:0]  newthread;
reg [1:0]  newthreadq;
reg        LD_newthread;

reg [11:0] PC_adder_input;
reg [1:0]  round_mode_q1;

reg [10:0] REPEAT;

reg fp_ready_q2;
reg fp_sel_q2;

reg wrdisable;

reg adder_CI; 

reg [31:0] brlshft_ROR;
reg [31:0] brlshft_ROL;

wire rddisable; 

wire [2:0] shiftype;
wire [3:0] shiftamount;
wire [4:0] shiftamount1;
wire sb;
wire [16:0] sbits;

wire rdconstA;
wire [1:0] round_mode; 
//wire SWBRKdet;
wire rdcycl;
wire wrcycl;

wire [13:0] dest_q2;

wire [31:0] prvt_rddataA;  

wire [31:0] prvt_rddataB;   

wire [31:0] private_F128_rddataA; 
wire [31:0] private_F128_rddataB; 

wire [31:0] prvt_2k_rddataA; 
wire [31:0] global_1024_rddataA;
wire [31:0] global_F512_rddataA;
wire [31:0] global_I256_rddataA;
wire [31:0] global_32_rddataA;

wire [31:0] prvt_2k_rddataB;                                
wire [31:0] global_1024_rddataB;
wire [31:0] global_F512_rddataB;
wire [31:0] global_I256_rddataB;
wire [31:0] global_32_rddataB;

wire [31:0] ROM_4k_rddataA;

wire [3:0]  opcode;
wire [1:0]  constn;

wire [13:0] srcA;
wire [13:0] srcB;
wire [13:0] srcAout;
wire [13:0] srcBout;

wire [7:0] OPdest;    
wire [7:0] OPsrcA;
wire [7:0] OPsrcB;

wire sched_0;       
wire sched_1;
wire sched_2;
wire sched_3;

wire LOCKED;

wire [31:0] adder_out;
wire adder_CO;
wire adder_OVO;    
wire adder_ZO; 

wire [31:0] bitsel;
wire discont;

wire LD_PC;

wire rdprog; 
wire rdsrcA; 
wire rdsrcB;
wire [11:0] next_PC;  
wire RESET_IN;
wire RESET;

wire RPT_not_z;

wire sched_3q;
wire sched_2q;
wire sched_1q;
wire sched_0q;

wire [31:0] tr0_STATUSq2;
wire [31:0] tr1_STATUSq2;
wire [31:0] tr2_STATUSq2;
wire [31:0] tr3_STATUSq2;

wire [31:0] tr0_STATUS;
wire [31:0] tr1_STATUS;
wire [31:0] tr2_STATUS;
wire [31:0] tr3_STATUS;

wire [31:0] sin_out;
wire [31:0] cos_out;
wire [31:0] tan_out;
wire [31:0] cot_out;
wire [31:0] rcp_out;

wire pipe_flush;

wire [3:0] exc_codeA;
wire [3:0] exc_codeB;

wire fp_ready_q1;

wire tr0_rewind_PC;
wire tr1_rewind_PC;
wire tr2_rewind_PC;
wire tr3_rewind_PC;

wire tr3_invalid;  
wire tr3_divby0; 
wire tr3_overflow; 
wire tr3_underflow;
wire tr3_inexact;  

wire tr2_invalid;  
wire tr2_divby0; 
wire tr2_overflow; 
wire tr2_underflow;
wire tr2_inexact;  

wire tr1_invalid;  
wire tr1_divby0; 
wire tr1_overflow; 
wire tr1_underflow;
wire tr1_inexact;  

wire tr0_invalid;  
wire tr0_divby0; 
wire tr0_overflow; 
wire tr0_underflow;
wire tr0_inexact;

wire tr3_invalid_imm;  
wire tr3_divby0_imm;   
wire tr3_overflow_imm; 
wire tr3_underflow_imm;
wire tr3_inexact_imm;  

wire tr2_invalid_imm;  
wire tr2_divby0_imm;   
wire tr2_overflow_imm; 
wire tr2_underflow_imm;
wire tr2_inexact_imm;  

wire tr1_invalid_imm;  
wire tr1_divby0_imm;   
wire tr1_overflow_imm; 
wire tr1_underflow_imm;
wire tr1_inexact_imm;  

wire tr0_invalid_imm;  
wire tr0_divby0_imm;   
wire tr0_overflow_imm; 
wire tr0_underflow_imm;
wire tr0_inexact_imm;  

wire tr3_invalid_del;  
wire tr3_divby0_del;   
wire tr3_overflow_del; 
wire tr3_underflow_del;
wire tr3_inexact_del;  

wire tr2_invalid_del;  
wire tr2_divby0_del;   
wire tr2_overflow_del; 
wire tr2_underflow_del;
wire tr2_inexact_del;  

wire tr1_invalid_del;  
wire tr1_divby0_del;   
wire tr1_overflow_del; 
wire tr1_underflow_del;
wire tr1_inexact_del;  

wire tr0_invalid_del;  
wire tr0_divby0_del;   
wire tr0_overflow_del; 
wire tr0_underflow_del;
wire tr0_inexact_del;  

wire [11:0] tr3_LPCNT1_dec;
wire [11:0] tr3_LPCNT0_dec;
wire [11:0] tr2_LPCNT1_dec;
wire [11:0] tr2_LPCNT0_dec;
wire [11:0] tr1_LPCNT1_dec;
wire [11:0] tr1_LPCNT0_dec;
wire [11:0] tr0_LPCNT1_dec;
wire [11:0] tr0_LPCNT0_dec;

wire tr3_LPCNT1_nz;
wire tr3_LPCNT0_nz;
wire tr2_LPCNT1_nz;
wire tr2_LPCNT0_nz;
wire tr1_LPCNT1_nz;
wire tr1_LPCNT0_nz;
wire tr0_LPCNT1_nz;
wire tr0_LPCNT0_nz;

wire tr3_NMI;
wire tr2_NMI;
wire tr1_NMI;
wire tr0_NMI;

wire tr3_IRQ;
wire tr2_IRQ;
wire tr1_IRQ;
wire tr0_IRQ;

wire [11:0] tr0_vector;
wire tr0_ld_vector;
wire tr0_NMI_ack;  
wire tr0_EXC_ack;  
wire tr0_IRQ_ack;  

wire [11:0] tr1_vector;
wire tr1_ld_vector;
wire tr1_NMI_ack;  
wire tr1_EXC_ack;  
wire tr1_IRQ_ack;  

wire [11:0] tr2_vector;
wire tr2_ld_vector;
wire tr2_NMI_ack;  
wire tr2_EXC_ack;                                                                    
wire tr2_IRQ_ack;                                                                    
                                                                                     
wire [11:0] tr3_vector;
wire tr3_ld_vector;
wire tr3_NMI_ack;  
wire tr3_EXC_ack;  
wire tr3_IRQ_ack; 

wire [31:0] tr0_capt_dataA;
wire [31:0] tr0_capt_dataB;

wire [31:0] tr1_capt_dataA;
wire [31:0] tr1_capt_dataB;

wire [31:0] tr2_capt_dataA;
wire [31:0] tr2_capt_dataB;

wire [31:0] tr3_capt_dataA;
wire [31:0] tr3_capt_dataB;

wire tr0_EXC_in_service;      
wire tr0_invalid_in_service;  
wire tr0_divby0_in_service;   
wire tr0_overflow_in_service; 
wire tr0_underflow_in_service;
wire tr0_inexact_in_service;  

wire tr1_EXC_in_service;      
wire tr1_invalid_in_service;  
wire tr1_divby0_in_service;   
wire tr1_overflow_in_service; 
wire tr1_underflow_in_service;
wire tr1_inexact_in_service;  

wire tr2_EXC_in_service;      
wire tr2_invalid_in_service;  
wire tr2_divby0_in_service;                                                                                                            
wire tr2_overflow_in_service;                                                                                                          
wire tr2_underflow_in_service;                                                                                                         
wire tr2_inexact_in_service;                                                                                                           

wire tr3_EXC_in_service;                                                                                                               
wire tr3_invalid_in_service;                                                                                                           
wire tr3_divby0_in_service;                                                                                                            
wire tr3_overflow_in_service;                                                                                                          
wire tr3_underflow_in_service;
wire tr3_inexact_in_service;

wire tr3_CREG_wr;                                                                                                           
wire tr2_CREG_wr;                                                                                                           
wire tr1_CREG_wr;                                                                                                           
wire tr0_CREG_wr;                                                                                                           
        
assign tr3_CREG_wr = wrcycl & (dest_q2==CREG_ADDRS) & (thread_q2==2'b11);                                                                                                           
assign tr2_CREG_wr = wrcycl & (dest_q2==CREG_ADDRS) & (thread_q2==2'b10);                                                                                                           
assign tr1_CREG_wr = wrcycl & (dest_q2==CREG_ADDRS) & (thread_q2==2'b01);                                                                                                           
assign tr0_CREG_wr = wrcycl & (dest_q2==CREG_ADDRS) & (thread_q2==2'b00);                                                                                                           

assign tr3_invalid   = tr3_invalid_imm;
assign tr3_divby0    = tr3_alt_del_div0  ? tr3_divby0_del    : tr3_divby0_imm;
assign tr3_overflow  = tr3_alt_del_ovfl  ? tr3_overflow_del  : tr3_overflow_imm;
assign tr3_underflow = tr3_alt_del_unfl  ? tr3_underflow_del : tr3_underflow_imm;
assign tr3_inexact   = tr3_alt_del_nxact ? tr3_inexact_del   : tr3_inexact_imm;
                                                                                                                                       
assign tr2_invalid   = tr2_invalid_imm;
assign tr2_divby0    = tr2_alt_del_div0  ? tr2_divby0_del    : tr2_divby0_imm;
assign tr2_overflow  = tr2_alt_del_ovfl  ? tr2_overflow_del  : tr2_overflow_imm;
assign tr2_underflow = tr2_alt_del_unfl  ? tr2_underflow_del : tr2_underflow_imm;
assign tr2_inexact   = tr2_alt_del_nxact ? tr2_inexact_del   : tr2_inexact_imm;

assign tr1_invalid   = tr1_invalid_imm;
assign tr1_divby0    = tr1_alt_del_div0  ? tr1_divby0_del    : tr1_divby0_imm;
assign tr1_overflow  = tr1_alt_del_ovfl  ? tr1_overflow_del  : tr1_overflow_imm;
assign tr1_underflow = tr1_alt_del_unfl  ? tr1_underflow_del : tr1_underflow_imm;
assign tr1_inexact   = tr1_alt_del_nxact ? tr1_inexact_del   : tr1_inexact_imm;

assign tr0_invalid   = tr0_invalid_imm;
assign tr0_divby0    = tr0_alt_del_div0  ? tr0_divby0_del    : tr0_divby0_imm;
assign tr0_overflow  = tr0_alt_del_ovfl  ? tr0_overflow_del  : tr0_overflow_imm;
assign tr0_underflow = tr0_alt_del_unfl  ? tr0_underflow_del : tr0_underflow_imm;
assign tr0_inexact   = tr0_alt_del_nxact ? tr0_inexact_del   : tr0_inexact_imm;

        
assign fp_sel_q1 = (((~|srcA_q1[12:8] & srcA_q1[7]) & ~constn_q1[1]) | ((~|srcB_q1[12:8] & srcB_q1[7]) & ~constn_q1[0])) & ~(opcode_q1==BTB_);

assign tr0_rewind_PC = (opcode_q2[3:2]==2'b00) & ~fp_ready_q2 & (thread_q2==2'b00) & fp_sel_q2;
assign tr1_rewind_PC = (opcode_q2[3:2]==2'b00) & ~fp_ready_q2 & (thread_q2==2'b01) & fp_sel_q2;
assign tr2_rewind_PC = (opcode_q2[3:2]==2'b00) & ~fp_ready_q2 & (thread_q2==2'b10) & fp_sel_q2;
assign tr3_rewind_PC = (opcode_q2[3:2]==2'b00) & ~fp_ready_q2 & (thread_q2==2'b11) & fp_sel_q2;

assign tr3_LPCNT1_dec = tr3_LPCNT1 - 1'b1;
assign tr3_LPCNT0_dec = tr3_LPCNT0 - 1'b1;
assign tr2_LPCNT1_dec = tr2_LPCNT1 - 1'b1;
assign tr2_LPCNT0_dec = tr2_LPCNT0 - 1'b1;
assign tr1_LPCNT1_dec = tr1_LPCNT1 - 1'b1;
assign tr1_LPCNT0_dec = tr1_LPCNT0 - 1'b1;
assign tr0_LPCNT1_dec = tr0_LPCNT1 - 1'b1;
assign tr0_LPCNT0_dec = tr0_LPCNT0 - 1'b1;

assign tr3_LPCNT1_nz = |tr3_LPCNT1_dec;
assign tr3_LPCNT0_nz = |tr3_LPCNT0_dec;
assign tr2_LPCNT1_nz = |tr2_LPCNT1_dec;
assign tr2_LPCNT0_nz = |tr2_LPCNT0_dec;
assign tr1_LPCNT1_nz = |tr1_LPCNT1_dec;
assign tr1_LPCNT0_nz = |tr1_LPCNT0_dec;
assign tr0_LPCNT1_nz = |tr0_LPCNT1_dec;
assign tr0_LPCNT0_nz = |tr0_LPCNT0_dec;

assign pipe_flush = |pipe_flush_tr0 | |pipe_flush_tr1 | |pipe_flush_tr2 | |pipe_flush_tr3;

assign RESET = RESET_IN;
assign RPT_not_z = |REPEAT;   

assign LOCKED = ((tr0_locked & (newthreadq==2'b00)) | (tr1_locked & (newthreadq==2'b01)) | (tr2_locked & (newthreadq==2'b10)) | (tr3_locked & (newthreadq==2'b11)));

assign next_PC = PC_adder_input + (~RPT_not_z ? 1'b1 : 1'b0);

assign sched_0 = |sched_cmp[7:0] & (scheduler[7:0] == sched_cmp[7:0]) & sched_state[0];  
assign sched_1 = |sched_cmp[15:8] & (scheduler[15:8] == sched_cmp[15:8]) & sched_state[1];
assign sched_2 = |sched_cmp[23:16] & (scheduler[23:16] == sched_cmp[23:16]) & sched_state[2];
assign sched_3 = |sched_cmp[31:24] & (scheduler[31:24] == sched_cmp[31:24]) & sched_state[3]; 

/*
assign sched_0 = sched_state[0];  //thread0
assign sched_1 = sched_state[1];  //thread1
assign sched_2 = sched_state[2];  //thread2
assign sched_3 = sched_state[3];  //thread3
*/
assign srcA = srcAout;
assign srcB = srcBout; 

wire bitmatch;

assign bitmatch = (|(bitsel & wrsrcBdata)) ^ OPsrcA_q2[6];
   
assign discont = (((opcode_q2==BTB_) & bitmatch)      | 
                 ((dest_q2[12:0]==PC_ADDRS) & wrcycl) | 
                 tr0_ld_vector                        |
                 tr1_ld_vector                        |
                 tr2_ld_vector                        |
                 tr3_ld_vector                        |
                 tr0_rewind_PC                        |
                 tr1_rewind_PC                        |
                 tr2_rewind_PC                        |
                 tr3_rewind_PC                              
                 ); // goes high exactly one clock before PC discontinuity actually occurs

assign LD_PC = RESET ;

assign ACT_THREAD = LD_newthread ? newthread : newthreadq;

assign rdprog = 1'b1; 
assign rdsrcA = rdcycl & ~constn[1]; 
assign rdsrcB = rdcycl & ~constn[0]; 
                                
assign bitsel = 1'b1<< OPsrcA_q2[4:0];
assign OPdest = P_DATAi[23:16];    
assign OPsrcA = P_DATAi[15:8];
assign OPsrcB = P_DATAi[7:0];

assign round_mode = P_DATAi[31:30]; 
assign rddisable = 1'b0;
//assign SWBRKdet = (opcode_q2==BTB_) & (dest_q2==8'h00) & (OPsrcA==8'h1F) & (OPsrcB==8'h64) & ~discont;  //relative BTBS (to self) of REPEAT reg ALWAYS == swbrk
assign rdcycl = ~rddisable;
assign wrcycl = ~wrdisable & STATE[0] & ~pipe_flush;                                                        
assign opcode =  P_DATAi[27:24];

assign constn = P_DATAi[29:28];

assign sb = wrsrcAdata[31];

assign sbits = {sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb};

assign shiftype = srcB_q2[6:4];
assign shiftamount = srcB_q2[3:0];
assign shiftamount1 = shiftamount + 1'b1;

assign rdconstA =  constn[1] & ~constn[0];

assign global_F512_rddataA = 32'h0000_0000;
assign global_I256_rddataA = 32'h0000_0000;
assign global_F512_rddataB = 32'h0000_0000;
assign global_I256_rddataB = 32'h0000_0000;

assign tr0_NMI = ~tr0_done & (tr0_timer==tr0_timercmpr);
assign tr1_NMI = ~tr1_done & (tr1_timer==tr1_timercmpr);
assign tr2_NMI = ~tr2_done & (tr2_timer==tr2_timercmpr);
assign tr3_NMI = ~tr3_done & (tr3_timer==tr3_timercmpr);

assign  tr0_STATUS = {  2'b10,
                         tr0_Z | tr0_N,
                        6'b000000,
                         tr0_IRQ,                   // tr0 general-purpose interrupt request
                         tr0_IRQ_IE,                // tr0 general-purpose interrupt request interrupt enable
                         tr0_alt_del_nxact,         // 1 = alternate delayed handler, 0 = immediate
                         tr0_alt_del_unfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr0_alt_del_ovfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr0_alt_del_div0,          // 1 = alternate delayed handler, 0 = immediate
                         tr0_alt_del_inv,           // 1 = alternate delayed handler, 0 = immediate
                         tr0_alt_nxact_handl,       // enable interrupt for alternate inexact exception handler
                         tr0_alt_unfl_handl,        // enable interrupt for alternate underflow exception handler
                         tr0_alt_ovfl_handl,        // enable interrupt for alternate overflow exception handler
                         tr0_alt_div0_handl,        // enable interrupt for alternate divide by 0 exception handler
                         tr0_alt_inv_handl,         // enable interrupt for alternate invalid operation exception handler
                         tr0_inexact_flag,          // flag indicating inexact result
                         tr0_underflow_flag,        // flag indicating result underflow
                         tr0_overflow_flag,         // flag indicating result overflow
                         tr0_divby0_flag,           // flag indicating result is from divide by zero (divide or log)
                         tr0_invalid_flag,          // flag indicating invalid operation
                         tr0_done, 
                         tr0_locked,
                         tr0_V,                     // integer overflow flag
                         tr0_N,                     // negative (sign) flag for both float and integer
                         tr0_C,                     // integer arithmatic carry flag "<" less than if set, ">=" greater than or equal to if cleared
                         tr0_Z                      // zero flag for both integer and float "==" equal to if set, "!=" not equal to if cleared
                         };            

assign  tr1_STATUS = {  2'b10,
                         tr1_Z | tr1_N,
                        6'b000000,
                         tr1_IRQ,                   // tr1 general-purpose interrupt request
                         tr1_IRQ_IE,                // tr1 general-purpose interrupt request interrupt enable
                         tr1_alt_del_nxact,         // 1 = alternate delayed handler, 0 = immediate
                         tr1_alt_del_unfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr1_alt_del_ovfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr1_alt_del_div0,          // 1 = alternate delayed handler, 0 = immediate
                         tr1_alt_del_inv,           // 1 = alternate delayed handler, 0 = immediate
                         tr1_alt_nxact_handl,       // enable interrupt for alternate inexact exception handler
                         tr1_alt_unfl_handl,        // enable interrupt for alternate underflow exception handler
                         tr1_alt_ovfl_handl,        // enable interrupt for alternate overflow exception handler
                         tr1_alt_div0_handl,        // enable interrupt for alternate divide by 0 exception handler
                         tr1_alt_inv_handl,         // enable interrupt for alternate invalid operation exception handler
                         tr1_inexact_flag,          // flag indicating inexact result
                         tr1_underflow_flag,        // flag indicating result underflow
                         tr1_overflow_flag,         // flag indicating result overflow
                         tr1_divby0_flag,           // flag indicating result is from divide by zero (divide or log)
                         tr1_invalid_flag,          // flag indicating invalid operation
                         tr1_done, 
                         tr1_locked,
                         tr1_V,     
                         tr1_N,     
                         tr1_C,                     // "<" less than if set, ">=" greater than or equal to if cleared
                         tr1_Z                      // "==" equal to if set, "!=" not equal to if cleared
                         };            
                         
assign  tr2_STATUS = {  2'b10,
                         tr2_Z | tr2_N,
                         6'b000000,
                         tr2_IRQ,                   // tr2 general-purpose interrupt request
                         tr2_IRQ_IE,                // tr2 general-purpose interrupt request interrupt enable
                         tr2_alt_del_nxact,         // 1 = alternate delayed handler, 0 = immediate
                         tr2_alt_del_unfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr2_alt_del_ovfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr2_alt_del_div0,          // 1 = alternate delayed handler, 0 = immediate
                         tr2_alt_del_inv,           // 1 = alternate delayed handler, 0 = immediate
                         tr2_alt_nxact_handl,       // enable interrupt for alternate inexact exception handler
                         tr2_alt_unfl_handl,        // enable interrupt for alternate underflow exception handler
                         tr2_alt_ovfl_handl,        // enable interrupt for alternate overflow exception handler
                         tr2_alt_div0_handl,        // enable interrupt for alternate divide by 0 exception handler
                         tr2_alt_inv_handl,         // enable interrupt for alternate invalid operation exception handler
                         tr2_inexact_flag,          // flag indicating inexact result
                         tr2_underflow_flag,        // flag indicating result underflow
                         tr2_overflow_flag,         // flag indicating result overflow
                         tr2_divby0_flag,           // flag indicating result is from divide by zero (divide or log)
                         tr2_invalid_flag,          // flag indicating invalid operation
                         tr2_done, 
                         tr2_locked,
                         tr2_V,     
                         tr2_N,     
                         tr2_C,                     // "<" less than if set, ">=" greater than or equal to if cleared
                         tr2_Z                      // "==" equal to if set, "!=" not equal to if cleared
                         };            

assign  tr3_STATUS = {  2'b10,
                         tr3_Z | tr3_N,
                        6'b000000,
                         tr3_IRQ,                   // tr3 general-purpose interrupt request
                         tr3_IRQ_IE,                // tr3 general-purpose interrupt request interrupt enable
                         tr3_alt_del_nxact,         // 1 = alternate delayed handler, 0 = immediate
                         tr3_alt_del_unfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr3_alt_del_ovfl,          // 1 = alternate delayed handler, 0 = immediate
                         tr3_alt_del_div0,          // 1 = alternate delayed handler, 0 = immediate
                         tr3_alt_del_inv,           // 1 = alternate delayed handler, 0 = immediate
                         tr3_alt_nxact_handl,       // enable interrupt for alternate inexact exception handler
                         tr3_alt_unfl_handl,        // enable interrupt for alternate underflow exception handler
                         tr3_alt_ovfl_handl,        // enable interrupt for alternate overflow exception handler
                         tr3_alt_div0_handl,        // enable interrupt for alternate divide by 0 exception handler
                         tr3_alt_inv_handl,         // enable interrupt for alternate invalid operation exception handler
                         tr3_inexact_flag,          // flag indicating inexact result
                         tr3_underflow_flag,        // flag indicating result underflow
                         tr3_overflow_flag,         // flag indicating result overflow
                         tr3_divby0_flag,           // flag indicating result is from divide by zero (divide or log)
                         tr3_invalid_flag,          // flag indicating invalid operation
                         tr3_done, 
                         tr3_locked,
                         tr3_V,     
                         tr3_N,     
                         tr3_C,                     // "<" less than if set, ">=" greater than or equal to if cleared
                         tr3_Z                      // "==" equal to if set, "!=" not equal to if cleared
                         };            
                         
assign  tr0_STATUSq2 = {2'b10,
                         Z_q2 | N_q2,
                         6'b000000,
                         tr0_IRQ,                    // tr0 general-purpose interrupt request
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[21] : tr0_IRQ_IE,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[20] : tr0_alt_del_nxact,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[19] : tr0_alt_del_unfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[18] : tr0_alt_del_ovfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[17] : tr0_alt_del_div0,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[16] : tr0_alt_del_inv,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[15] : tr0_alt_nxact_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[14] : tr0_alt_unfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[13] : tr0_alt_ovfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[12] : tr0_alt_div0_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[11] : tr0_alt_inv_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[10] : tr0_inexact_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[9]  : tr0_underflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[8]  : tr0_overflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[7]  : tr0_divby0_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[6]  : tr0_invalid_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[5]  : tr0_done, 
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[4]  : tr0_locked,
                         V_q2,     
                         N_q2,     
                         C_q2,     
                         Z_q2
                         };
                         
assign  tr1_STATUSq2 = {2'b10,
                         Z_q2 | N_q2,
                        6'b000000,
                         tr1_IRQ,                    // tr1 general-purpose interrupt request
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[21] : tr1_IRQ_IE,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[20] : tr1_alt_del_nxact,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[19] : tr1_alt_del_unfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[18] : tr1_alt_del_ovfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[17] : tr1_alt_del_div0,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[16] : tr1_alt_del_inv,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[15] : tr1_alt_nxact_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[14] : tr1_alt_unfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[13] : tr1_alt_ovfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[12] : tr1_alt_div0_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[11] : tr1_alt_inv_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[10] : tr1_inexact_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[9]  : tr1_underflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[8]  : tr1_overflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[7]  : tr1_divby0_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[6]  : tr1_invalid_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[5]  : tr1_done, 
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[4]  : tr1_locked,
                         V_q2,     
                         N_q2,     
                         C_q2,     
                         Z_q2
                         };
                                                  
assign  tr2_STATUSq2 = {2'b10,
                         Z_q2 | N_q2,
                        6'b000000,
                         tr2_IRQ,                    // tr2 general-purpose interrupt request
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[21] : tr2_IRQ_IE,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[20] : tr2_alt_del_nxact,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[19] : tr2_alt_del_unfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[18] : tr2_alt_del_ovfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[17] : tr2_alt_del_div0,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[16] : tr2_alt_del_inv,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[15] : tr2_alt_nxact_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[14] : tr2_alt_unfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[13] : tr2_alt_ovfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[12] : tr2_alt_div0_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[11] : tr2_alt_inv_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[10] : tr2_inexact_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[9]  : tr2_underflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[8]  : tr2_overflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[7]  : tr2_divby0_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[6]  : tr2_invalid_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[5]  : tr2_done, 
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[4]  : tr2_locked,
                         V_q2,     
                         N_q2,     
                         C_q2,     
                         Z_q2
                         };
                         
assign  tr3_STATUSq2 = {2'b10,
                         Z_q2 | N_q2,
                        6'b000000,
                         tr3_IRQ,                    // tr3 general-purpose interrupt request
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[21] : tr3_IRQ_IE,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[20] : tr3_alt_del_nxact,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[19] : tr3_alt_del_unfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[18] : tr3_alt_del_ovfl,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[17] : tr3_alt_del_div0,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[16] : tr3_alt_del_inv,                         
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[15] : tr3_alt_nxact_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[14] : tr3_alt_unfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[13] : tr3_alt_ovfl_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[12] : tr3_alt_div0_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[11] : tr3_alt_inv_handl,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[10] : tr3_inexact_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[9]  : tr3_underflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[8]  : tr3_overflow_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[7]  : tr3_divby0_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[6]  : tr3_invalid_flag,
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[5]  : tr3_done, 
                         ((dest_q2==ST_ADDRS) & wrcycl) ? resultout[4]  : tr3_locked,
                         V_q2,     
                         N_q2,     
                         C_q2,     
                         Z_q2
                         };
                                                  
DATA_ADDRS_mod data_addrs_mod(                          
    .tr3_AR3       (tr3_AR3[13:0]),
    .tr3_AR2       (tr3_AR2[13:0]),
    .tr3_AR1       (tr3_AR1[13:0]),
    .tr3_AR0       (tr3_AR0[13:0]),
    .tr2_AR3       (tr2_AR3[13:0]),
    .tr2_AR2       (tr2_AR2[13:0]),
    .tr2_AR1       (tr2_AR1[13:0]),
    .tr2_AR0       (tr2_AR0[13:0]),
    .tr1_AR3       (tr1_AR3[13:0]),
    .tr1_AR2       (tr1_AR2[13:0]),
    .tr1_AR1       (tr1_AR1[13:0]),
    .tr1_AR0       (tr1_AR0[13:0]),
    .tr0_AR3       (tr0_AR3[13:0]),
    .tr0_AR2       (tr0_AR2[13:0]),
    .tr0_AR1       (tr0_AR1[13:0]),
    .tr0_AR0       (tr0_AR0[13:0]),
    .constn        (constn     ),
    .OPdest_q2     (OPdest_q2 ),
    .OPsrcA        (OPsrcA    ),
    .OPsrcB        (OPsrcB    ),
    .ACT_THREAD    (newthreadq),
    .thread_q2     (thread_q2),
    .dest          (dest_q2   ),
    .srcA          (srcAout   ),
    .srcB          (srcBout   )
    );   

ADDER_32 adder_32 (
    .SUBTRACT ((opcode_q2 == SUB_) | (opcode_q2 == SUBB_)),
    .TERM_A   (wrsrcAdata),       
    .TERM_B   (wrsrcBdata), 
    .CI       (((opcode_q2 == ADDC_) | (opcode_q2 == SUBB_))? adder_CI : 1'b0),  // carry in
    .ADDER_OUT(adder_out ), // adder out
    .CO       (adder_CO ),  // carry out
    .HCO      ( ),          // half carry out (aka aux. carry)
    .OVO      (adder_OVO ), // overflow out
    .ZERO     (adder_ZO )); // zero out


aSYMPL_func fpmath( 
   .RESET    (RESET),
   .CLK      (CLK ),
   .pc_q2    (pc_q2),
   .thread   (newthreadq),
   .thread_q1(thread_q1),
   .thread_q2(thread_q2),
   .opcode_q1(opcode_q1),
   .constn_q1 (constn_q1 ),
   .OPsrcA_q1(OPsrcA_q1),
   .OPsrcB_q1(OPsrcB_q1),
   .wren     (wrcycl & ~|dest_q2[13:8] & dest_q2[7]),
   .wraddrs  (dest_q2[6:0]),
   .rdSrcAdata (rdSrcAdata ),
   .rdSrcBdata (rdSrcBdata ),
   .rdenA    (rdsrcA & ~|srcA[13:8] & srcA[7]),
   .rdaddrsA (srcA[7:0]),
   .rddataA  (private_F128_rddataA),
   .rdenB    (rdsrcB & ~|srcB[13:8] & srcB[7]),
   .rddataB  (private_F128_rddataB),
   .rdaddrsB (srcB[7:0]),
   .tr0_C_reg(tr0_C_reg ),
   .tr1_C_reg(tr1_C_reg ),
   .tr2_C_reg(tr2_C_reg ),
   .tr3_C_reg(tr3_C_reg ),
   .exc_codeA(exc_codeA ), 
   .exc_codeB(exc_codeB ),
   
   .tr3_CREG_wr(tr3_CREG_wr), 
   .tr2_CREG_wr(tr2_CREG_wr), 
   .tr1_CREG_wr(tr1_CREG_wr), 
   .tr0_CREG_wr(tr0_CREG_wr), 
   
   .ready    (fp_ready_q1),
   
   .round_mode_q1(round_mode_q1    ),
   
   .tr3_invalid  (tr3_invalid_imm  ),
   .tr3_div_by_0 (tr3_divby0_imm   ),
   .tr3_overflow (tr3_overflow_imm ),
   .tr3_underflow(tr3_underflow_imm),
   .tr3_inexact  (tr3_inexact_imm  ),
   
   .tr2_invalid  (tr2_invalid_imm  ),
   .tr2_div_by_0 (tr2_divby0_imm   ),
   .tr2_overflow (tr2_overflow_imm ),
   .tr2_underflow(tr2_underflow_imm),
   .tr2_inexact  (tr2_inexact_imm  ),
   
   .tr1_invalid  (tr1_invalid_imm  ),
   .tr1_div_by_0 (tr1_divby0_imm   ),
   .tr1_overflow (tr1_overflow_imm ),
   .tr1_underflow(tr1_underflow_imm),
   .tr1_inexact  (tr1_inexact_imm  ),
   
   .tr0_invalid  (tr0_invalid_imm  ),
   .tr0_div_by_0 (tr0_divby0_imm   ),
   .tr0_overflow (tr0_overflow_imm ),
   .tr0_underflow(tr0_underflow_imm),
   .tr0_inexact  (tr0_inexact_imm  )
   );
/*
    assign private_F128_rddataA = 32'h0000_0000;
    assign private_F128_rddataB = 32'h0000_0000;
    assign fp_flags = 2'b00;
    assign fp_ready_q1 = 1'b1;
*/


func_atomic fatomic(
    .wrdata    (wrsrcAdata[9:0]),     
    .opcode_q2 (opcode_q2 ),
    .sin_out   (sin_out   ),
    .cos_out   (cos_out   ),
    .tan_out   (tan_out   ),
    .cot_out   (cot_out   ),
    .rcp_out   (rcp_out   ));

/*
    assign sin_out = 32'h0000_0000;
    assign cos_out = 32'h0000_0000;
    assign tan_out = 32'h0000_0000;
    assign cot_out = 32'h0000_0000;
    assign rcp_out = 32'h0000_0000;
*/


// this is global 1024 starting at 0x0400, shared by all threads
RAM_tp #(.ADDRS_WIDTH(10), .DATA_WIDTH(32))
    global_1024 (  
    .CLK(CLK),
    .wren(wrcycl & (dest_q2[13:10]==4'b0001)),
    .wraddrs(dest_q2[9:0]),
    .wrdata(resultout),
    .rdenA(rdsrcA & (srcA[13:10]==4'b0001)),
    .rdaddrsA(srcA[9:0]),
    .rddataA(global_1024_rddataA),
    .rdenB(rdsrcB & (srcB[13:10]==4'b0001)),
    .rdaddrsB(srcB[9:0]),
    .rddataB(global_1024_rddataB));
        
RAM_tp #(.ADDRS_WIDTH(5), .DATA_WIDTH(32))
     global_32 (
     .CLK(CLK),
     .wren(wrcycl & (dest_q2[13:5]==9'h002)),
     .wraddrs(dest_q2[4:0]),
     .wrdata(resultout),
     .rdenA(rdsrcA & (srcA[13:5]==9'h002)),
     .rdaddrsA(srcA[4:0]),
     .rddataA(global_32_rddataA),
     .rdenB(rdsrcB & (srcB[13:5]==9'h002)),
     .rdaddrsB(srcB[4:0]),
     .rddataB(global_32_rddataB));           

RAM_tp #(.ADDRS_WIDTH(8), .DATA_WIDTH(32))
    prvt_64(
    .CLK(CLK),
    .wren(wrcycl & (dest_q2[13:6]==8'b00_0000_00)),
    .wraddrs({thread_q2[1:0], dest_q2[5:0]}),
    .wrdata(resultout),
    .rdenA(rdsrcA & (srcA[13:6]==8'b00_0000_00)),
    .rdaddrsA({newthreadq[1:0], srcA[5:0]}),
    .rddataA(prvt_rddataA),
    .rdenB(rdsrcB & (srcB[13:6]==8'b00_0000_00)),
    .rdaddrsB({newthreadq[1:0], srcB[5:0]}),
    .rddataB(prvt_rddataB));  

int_cntrl int_cntrl_tr0(
    .CLK                  (CLK          ),
    .RESET                (RESET        ),
    .PC                   (PC           ),
    .opcode_q2            (opcode_q2    ),
    .thread               (newthreadq   ),
    .thread_q2            (thread_q2    ),
    .srcA_q2              (srcA_q2      ),
    .dest_q2              (dest_q2      ),
    .NMI                  (tr0_NMI      ),
    .inexact_exc          (tr0_inexact   & tr0_alt_nxact_handl),
    .underflow_exc        (tr0_underflow & tr0_alt_unfl_handl ),
    .overflow_exc         (tr0_overflow  & tr0_alt_ovfl_handl ),
    .divby0_exc           (tr0_divby0    & tr0_alt_div0_handl ),
    .invalid_exc          (tr0_invalid   & tr0_alt_inv_handl  ),
    .IRQ                  (tr0_IRQ      ),
    .IRQ_IE               (tr0_IRQ_IE   ),
    .vector               (tr0_vector   ),
    .ld_vector            (tr0_ld_vector),
    .NMI_ack              (tr0_NMI_ack  ),
    .EXC_ack              (tr0_EXC_ack  ),
    .IRQ_ack              (tr0_IRQ_ack  ),
    .EXC_in_service       (tr0_EXC_in_service      ),
    .invalid_in_service   (tr0_invalid_in_service  ),
    .divby0_in_service    (tr0_divby0_in_service   ),
    .overflow_in_service  (tr0_overflow_in_service ),
    .underflow_in_service (tr0_underflow_in_service),
    .inexact_in_service   (tr0_inexact_in_service  ),
    .wrcycl               (wrcycl       ),
    .pipe_flush           (|pipe_flush_tr0),
    .assigned_thread      (2'b00        )
    );   

int_cntrl int_cntrl_tr1(
    .CLK                  (CLK          ),
    .RESET                (RESET        ),
    .PC                   (PC           ),
    .opcode_q2            (opcode_q2    ),
    .thread               (newthreadq   ),
    .thread_q2            (thread_q2    ),
    .srcA_q2              (srcA_q2      ),
    .dest_q2              (dest_q2      ),
    .NMI                  (tr1_NMI      ),
    .inexact_exc          (tr1_inexact   & tr1_alt_nxact_handl),
    .underflow_exc        (tr1_underflow & tr1_alt_unfl_handl ),
    .overflow_exc         (tr1_overflow  & tr1_alt_ovfl_handl ),
    .divby0_exc           (tr1_divby0    & tr1_alt_div0_handl ),
    .invalid_exc          (tr1_invalid   & tr1_alt_inv_handl  ),
    .IRQ                  (tr1_IRQ      ),
    .IRQ_IE               (tr1_IRQ_IE   ),
    .vector               (tr1_vector   ),
    .ld_vector            (tr1_ld_vector),
    .NMI_ack              (tr1_NMI_ack  ),
    .EXC_ack              (tr1_EXC_ack  ),
    .IRQ_ack              (tr1_IRQ_ack  ),
    .EXC_in_service       (tr1_EXC_in_service      ),
    .invalid_in_service   (tr1_invalid_in_service  ),
    .divby0_in_service    (tr1_divby0_in_service   ),
    .overflow_in_service  (tr1_overflow_in_service ),
    .underflow_in_service (tr1_underflow_in_service),
    .inexact_in_service   (tr1_inexact_in_service  ),
    .wrcycl               (wrcycl       ),
    .pipe_flush           (|pipe_flush_tr1),
    .assigned_thread      (2'b01        )
    );   

int_cntrl int_cntrl_tr2(
    .CLK                  (CLK          ),
    .RESET                (RESET        ),
    .PC                   (PC           ),
    .opcode_q2            (opcode_q2    ),
    .thread               (newthreadq   ),
    .thread_q2            (thread_q2    ),
    .srcA_q2              (srcA_q2      ),
    .dest_q2              (dest_q2      ),
    .NMI                  (tr2_NMI      ),
    .inexact_exc          (tr2_inexact   & tr2_alt_nxact_handl),
    .underflow_exc        (tr2_underflow & tr2_alt_unfl_handl ),
    .overflow_exc         (tr2_overflow  & tr2_alt_ovfl_handl ),
    .divby0_exc           (tr2_divby0    & tr2_alt_div0_handl ),
    .invalid_exc          (tr2_invalid   & tr2_alt_inv_handl  ),
    .IRQ                  (tr2_IRQ      ),
    .IRQ_IE               (tr2_IRQ_IE   ),
    .vector               (tr2_vector   ),
    .ld_vector            (tr2_ld_vector),
    .NMI_ack              (tr2_NMI_ack  ),
    .EXC_ack              (tr2_EXC_ack  ),
    .IRQ_ack              (tr2_IRQ_ack  ),
    .EXC_in_service       (tr2_EXC_in_service      ),
    .invalid_in_service   (tr2_invalid_in_service  ),
    .divby0_in_service    (tr2_divby0_in_service   ),
    .overflow_in_service  (tr2_overflow_in_service ),
    .underflow_in_service (tr2_underflow_in_service),
    .inexact_in_service   (tr2_inexact_in_service  ),
    .wrcycl               (wrcycl       ),
    .pipe_flush           (|pipe_flush_tr2),
    .assigned_thread      (2'b10        )
    );   

int_cntrl int_cntrl_tr3(
    .CLK                  (CLK          ),
    .RESET                (RESET        ),
    .PC                   (PC           ),
    .opcode_q2            (opcode_q2    ),
    .thread               (newthreadq   ),
    .thread_q2            (thread_q2    ),
    .srcA_q2              (srcA_q2      ),
    .dest_q2              (dest_q2      ),
    .NMI                  (tr3_NMI      ),
    .inexact_exc          (tr3_inexact   & tr3_alt_nxact_handl),
    .underflow_exc        (tr3_underflow & tr3_alt_unfl_handl ),
    .overflow_exc         (tr3_overflow  & tr3_alt_ovfl_handl ),
    .divby0_exc           (tr3_divby0    & tr3_alt_div0_handl ),
    .invalid_exc          (tr3_invalid   & tr3_alt_inv_handl  ),
    .IRQ                  (tr3_IRQ      ),
    .IRQ_IE               (tr3_IRQ_IE   ),
    .vector               (tr3_vector   ),
    .ld_vector            (tr3_ld_vector),
    .NMI_ack              (tr3_NMI_ack  ),
    .EXC_ack              (tr3_EXC_ack  ),
    .IRQ_ack              (tr3_IRQ_ack  ),
    .EXC_in_service       (tr3_EXC_in_service      ),
    .invalid_in_service   (tr3_invalid_in_service  ),
    .divby0_in_service    (tr3_divby0_in_service   ),
    .overflow_in_service  (tr3_overflow_in_service ),
    .underflow_in_service (tr3_underflow_in_service),
    .inexact_in_service   (tr3_inexact_in_service  ),
    .wrcycl               (wrcycl       ),
    .pipe_flush           (|pipe_flush_tr3),
    .assigned_thread      (2'b11        )
    );  
    
    
exc_capture exc_capt3(     // quasi-trace buffer
    .CLK            (CLK        ),
    .RESET          (tr3_done   ),
    .srcA_q1        (srcA_q1    ),
    .srcB_q1        (srcB_q1    ),
    .addrsMode_q1   (constn_q1  ),
    .dest_q2        (dest_q2    ),
    .pc_q1          (pc_q1      ),
    .rdSrcAdata     (private_F128_rddataA),
    .rdSrcBdata     (private_F128_rddataB),
    .exc_codeA      (exc_codeA  ),
    .exc_codeB      (exc_codeB  ),
    .rdenA          (rdsrcA & (srcA[13:2]==11'b0_0000_0110_00)),
    .rdenB          (rdsrcB & (srcB[13:2]==11'b0_0000_0110_00)),
    .thread_q1      (thread_q1           ),
    .round_mode_q1  (round_mode_q1       ),
    .ready_in       (fp_ready_q1         ),
    .alt_nxact_handl(tr3_alt_nxact_handl ),
    .alt_unfl_handl (tr3_alt_unfl_handl  ),
    .alt_ovfl_handl (tr3_alt_ovfl_handl  ),
    .alt_div0_handl (tr3_alt_div0_handl  ),
    .alt_inv_handl  (tr3_alt_inv_handl   ),
    .invalid        (tr3_invalid_del     ),
    .divby0         (tr3_divby0_del      ),
    .overflow       (tr3_overflow_del    ),
    .underflow      (tr3_underflow_del   ),
    .inexact        (tr3_inexact_del     ),
    .capt_dataA     (tr3_capt_dataA      ),
    .capt_dataB     (tr3_capt_dataB      ),
    .thread_sel     (2'b00               )
    );                                      
                                        
exc_capture exc_capt2(     // quasi-trace buffer
    .CLK            (CLK        ),
    .RESET          (tr2_done   ),
    .srcA_q1        (srcA_q1    ),
    .srcB_q1        (srcB_q1    ),
    .addrsMode_q1   (constn_q1  ),
    .dest_q2        (dest_q2    ),
    .pc_q1          (pc_q1      ),
    .rdSrcAdata     (private_F128_rddataA),
    .rdSrcBdata     (private_F128_rddataB),
    .exc_codeA      (exc_codeA  ),
    .exc_codeB      (exc_codeB  ),
    .rdenA          (rdsrcA & (srcA[13:2]==11'b0_0000_0110_00)),
    .rdenB          (rdsrcB & (srcB[13:2]==11'b0_0000_0110_00)),
    .thread_q1      (thread_q1           ),
    .round_mode_q1  (round_mode_q1       ),
    .ready_in       (fp_ready_q1         ),
    .alt_nxact_handl(tr2_alt_nxact_handl ),
    .alt_unfl_handl (tr2_alt_unfl_handl  ),
    .alt_ovfl_handl (tr2_alt_ovfl_handl  ),
    .alt_div0_handl (tr2_alt_div0_handl  ),
    .alt_inv_handl  (tr2_alt_inv_handl   ),
    .invalid        (tr2_invalid_del     ),
    .divby0         (tr2_divby0_del      ),
    .overflow       (tr2_overflow_del    ),
    .underflow      (tr2_underflow_del   ),
    .inexact        (tr2_inexact_del     ),
    .capt_dataA     (tr2_capt_dataA      ),
    .capt_dataB     (tr2_capt_dataB      ),
    .thread_sel     (2'b00               )
    );                                      

exc_capture exc_capt1(     // quasi-trace buffer
    .CLK            (CLK        ),
    .RESET          (tr1_done   ),
    .srcA_q1        (srcA_q1    ),
    .srcB_q1        (srcB_q1    ),
    .addrsMode_q1   (constn_q1  ),
    .dest_q2        (dest_q2    ),
    .pc_q1          (pc_q1      ),
    .rdSrcAdata     (private_F128_rddataA),
    .rdSrcBdata     (private_F128_rddataB),
    .exc_codeA      (exc_codeA  ),
    .exc_codeB      (exc_codeB  ),
    .rdenA          (rdsrcA & (srcA[13:2]==11'b0_0000_0110_00)),
    .rdenB          (rdsrcB & (srcB[13:2]==11'b0_0000_0110_00)),
    .thread_q1      (thread_q1           ),
    .round_mode_q1  (round_mode_q1       ),
    .ready_in       (fp_ready_q1         ),
    .alt_nxact_handl(tr1_alt_nxact_handl ),
    .alt_unfl_handl (tr1_alt_unfl_handl  ),
    .alt_ovfl_handl (tr1_alt_ovfl_handl  ),
    .alt_div0_handl (tr1_alt_div0_handl  ),
    .alt_inv_handl  (tr1_alt_inv_handl   ),
    .invalid        (tr1_invalid_del     ),
    .divby0         (tr1_divby0_del      ),
    .overflow       (tr1_overflow_del    ),
    .underflow      (tr1_underflow_del   ),
    .inexact        (tr1_inexact_del     ),
    .capt_dataA     (tr1_capt_dataA      ),
    .capt_dataB     (tr1_capt_dataB      ),
    .thread_sel     (2'b00               )
    );                                      

exc_capture exc_capt0(     // quasi-trace buffer
    .CLK            (CLK        ),
    .RESET          (tr1_done   ),
    .srcA_q1        (srcA_q1    ),
    .srcB_q1        (srcB_q1    ),
    .addrsMode_q1   (constn_q1  ),
    .dest_q2        (dest_q2    ),
    .pc_q1          (pc_q1      ),
    .rdSrcAdata     (private_F128_rddataA),
    .rdSrcBdata     (private_F128_rddataB),
    .exc_codeA      (exc_codeA  ),
    .exc_codeB      (exc_codeB  ),
    .rdenA          (rdsrcA & (srcA[13:2]==11'b0_0000_0110_00)),
    .rdenB          (rdsrcB & (srcB[13:2]==11'b0_0000_0110_00)),
    .thread_q1      (thread_q1           ),
    .round_mode_q1  (round_mode_q1       ),
    .ready_in       (fp_ready_q1         ),
    .alt_nxact_handl(tr0_alt_nxact_handl ),
    .alt_unfl_handl (tr0_alt_unfl_handl  ),
    .alt_ovfl_handl (tr0_alt_ovfl_handl  ),
    .alt_div0_handl (tr0_alt_div0_handl  ),
    .alt_inv_handl  (tr0_alt_inv_handl   ),
    .invalid        (tr0_invalid_del     ),
    .divby0         (tr0_divby0_del      ),
    .overflow       (tr0_overflow_del    ),
    .underflow      (tr0_underflow_del   ),
    .inexact        (tr0_inexact_del     ),
    .capt_dataA     (tr0_capt_dataA      ),
    .capt_dataB     (tr0_capt_dataB      ),
    .thread_sel     (2'b00               )
    );                                      
    
sched_stack sched_stack(
    .CLK       (CLK       ),
    .RESET     (RESET     ),
    .sched_3   (sched_3   ),
    .sched_2   (sched_2   ),
    .sched_1   (sched_1   ),
    .sched_0   (sched_0   ),
    .sched_3q  (sched_3q  ),
    .sched_2q  (sched_2q  ),
    .sched_1q  (sched_1q  ),
    .sched_0q  (sched_0q  ),
    .LOCKED    (LOCKED    ),
    .RPT_not_z (RPT_not_z ));  
    
always @(*) begin
    case (shiftamount)
        4'h0 : brlshft_ROR = {wrsrcAdata[0],    wrsrcAdata[31:1]} ;
        4'h1 : brlshft_ROR = {wrsrcAdata[1:0],  wrsrcAdata[31:2]} ;
        4'h2 : brlshft_ROR = {wrsrcAdata[2:0],  wrsrcAdata[31:3]} ;
        4'h3 : brlshft_ROR = {wrsrcAdata[3:0],  wrsrcAdata[31:4]} ;
        4'h4 : brlshft_ROR = {wrsrcAdata[4:0],  wrsrcAdata[31:5]} ;
        4'h5 : brlshft_ROR = {wrsrcAdata[5:0],  wrsrcAdata[31:6]} ;
        4'h6 : brlshft_ROR = {wrsrcAdata[6:0],  wrsrcAdata[31:7]} ;
        4'h7 : brlshft_ROR = {wrsrcAdata[7:0],  wrsrcAdata[31:8]} ;
        4'h8 : brlshft_ROR = {wrsrcAdata[8:0],  wrsrcAdata[31:9]} ;
        4'h9 : brlshft_ROR = {wrsrcAdata[9:0],  wrsrcAdata[31:10]};
        4'hA : brlshft_ROR = {wrsrcAdata[10:0], wrsrcAdata[31:11]};
        4'hB : brlshft_ROR = {wrsrcAdata[11:0], wrsrcAdata[31:12]};
        4'hC : brlshft_ROR = {wrsrcAdata[12:0], wrsrcAdata[31:13]};
        4'hD : brlshft_ROR = {wrsrcAdata[13:0], wrsrcAdata[31:14]};
        4'hE : brlshft_ROR = {wrsrcAdata[14:0], wrsrcAdata[31:15]};
        4'hF : brlshft_ROR = {wrsrcAdata[15:0], wrsrcAdata[31:16]};
    endcase
end  

always @(*) begin
    case (shiftamount)
        4'h0 : brlshft_ROL = {wrsrcAdata[30:0], wrsrcAdata[31]}   ;
        4'h1 : brlshft_ROL = {wrsrcAdata[29:0], wrsrcAdata[31:30]};
        4'h2 : brlshft_ROL = {wrsrcAdata[28:0], wrsrcAdata[31:29]};
        4'h3 : brlshft_ROL = {wrsrcAdata[27:0], wrsrcAdata[31:28]};
        4'h4 : brlshft_ROL = {wrsrcAdata[26:0], wrsrcAdata[31:27]};
        4'h5 : brlshft_ROL = {wrsrcAdata[25:0], wrsrcAdata[31:26]};
        4'h6 : brlshft_ROL = {wrsrcAdata[24:0], wrsrcAdata[31:25]};
        4'h7 : brlshft_ROL = {wrsrcAdata[23:0], wrsrcAdata[31:24]};
        4'h8 : brlshft_ROL = {wrsrcAdata[22:0], wrsrcAdata[31:23]};
        4'h9 : brlshft_ROL = {wrsrcAdata[21:0], wrsrcAdata[31:22]};
        4'hA : brlshft_ROL = {wrsrcAdata[20:0], wrsrcAdata[31:21]};
        4'hB : brlshft_ROL = {wrsrcAdata[19:0], wrsrcAdata[31:20]};
        4'hC : brlshft_ROL = {wrsrcAdata[18:0], wrsrcAdata[31:19]};
        4'hD : brlshft_ROL = {wrsrcAdata[17:0], wrsrcAdata[31:18]};
        4'hE : brlshft_ROL = {wrsrcAdata[16:0], wrsrcAdata[31:17]};
        4'hF : brlshft_ROL = {wrsrcAdata[15:0], wrsrcAdata[31:16]};
    endcase
end        

always @(*) begin
    case (thread_q2)
        2'b00 : adder_CI = tr0_C;  
        2'b01 : adder_CI = tr1_C;
        2'b10 : adder_CI = tr2_C;
        2'b11 : adder_CI = tr3_C;
    endcase
end                        
    
always @(*) begin
    if (STATE[1]) casex (opcode_q2)
        BTB_  : wrdisable = 1'b1;                
        
        MOV_  ,  // all other opcodes write is active during q2
        AND_  , 
        OR_   ,
        XOR_  , 
        SHFT_ ,
        ADDC_ ,
        ADD_  ,
        SUB_  ,
        SUBB_ ,
        MUL_  ,
        SIN_  ,
        COS_  ,
        TAN_  ,
        COT_  ,
        RCP_  : wrdisable = 1'b0;
    
        default : wrdisable = 1'b1;
        endcase
    else wrdisable = 1'b1;
end        


always @(*) begin
    casex (newthreadq)
        2'b00 : PC_adder_input = tr0_PC;
        2'b01 : PC_adder_input = tr1_PC;
        2'b10 : PC_adder_input = tr2_PC;
        2'b11 : PC_adder_input = tr3_PC;
    endcase  
end
      
always @(*) begin
    if (RESET) pre_PC = 12'h100;
    else if (LD_newthread)
       case (newthread) 
           2'b00 : pre_PC = tr0_PC;
           2'b01 : pre_PC = tr1_PC;
           2'b10 : pre_PC = tr2_PC;
           2'b11 : pre_PC = tr3_PC;
       endcase
    else if ((dest_q2[11:0] == PC_ADDRS) && wrcycl) pre_PC = resultout;
    else if ((opcode_q2 == BTB_) && |(bitsel & wrsrcBdata))  pre_PC = pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]}; 
    else pre_PC = next_PC;
end    

always @(*) begin 
    if (RESET) begin
        newthread = 2'b00;
        LD_newthread = 1'b0;
    end  
    
    else if (sched_0q && ~RPT_not_z  && |newthreadq) begin   //if already in thread0, don't do anything
        newthread = 2'b00;
        LD_newthread = 1'b1;    
    end  
    else if (sched_1q && ~RPT_not_z && ~(newthreadq == 2'b01)) begin //if already in thread1, don't do anything
        newthread = 2'b01;
        LD_newthread = 1'b1;    
    end  
   else if (sched_2q && ~RPT_not_z && ~(newthreadq == 2'b10)) begin //if already in thread2, don't do anything
        newthread = 2'b10;
        LD_newthread = 1'b1;    
    end  
    else if (sched_3q && ~RPT_not_z && ~(newthreadq == 2'b11)) begin //if already in thread3, don't do anything
        newthread = 2'b11;
        LD_newthread = 1'b1;    
    end  
    
/*   
    else if (~|newthreadq && rdprog && |thread && ~RPT_not_z) begin     // to move from thread 0 to thread 1, 2, or 3 
        newthread = thread;
        LD_newthread = 1'b1;
    end    
    else if (|newthreadq && rdprog && ~|(newthreadq ^ thread) && ~RPT_not_z) begin      // to move from thread 1, 2, or 3 to thread 0
        newthread = 2'b00;
        LD_newthread = 1'b1;
    end    
    else if (|newthreadq && rdprog && |thread && ~RPT_not_z) begin   //to move from thread 1, 2, or 3 to 2 or 3, 3 or 1, or 1 or 2
        newthread = thread;
        LD_newthread = 1'b1;
    end   
*/     
    else begin
//        newthread = thread; 
         newthread = 2'b00; 
       LD_newthread = 1'b0;
    end       
end
               
wire collision_srcA_tr3;
wire collision_srcB_tr3;
wire collision_srcA_tr2;
wire collision_srcB_tr2;
wire collision_srcA_tr1;
wire collision_srcB_tr1;
wire collision_srcA_tr0;
wire collision_srcB_tr0;

assign collision_srcA_tr3 = (srcA_q1==dest_q2) & wrcycl & (thread_q2==2'b11);
assign collision_srcB_tr3 = (srcB_q1==dest_q2) & wrcycl & (thread_q2==2'b11);
assign collision_srcA_tr2 = (srcA_q1==dest_q2) & wrcycl & (thread_q2==2'b10);
assign collision_srcB_tr2 = (srcB_q1==dest_q2) & wrcycl & (thread_q2==2'b10);
assign collision_srcA_tr1 = (srcA_q1==dest_q2) & wrcycl & (thread_q2==2'b01);
assign collision_srcB_tr1 = (srcB_q1==dest_q2) & wrcycl & (thread_q2==2'b01);
assign collision_srcA_tr0 = (srcA_q1==dest_q2) & wrcycl & (thread_q2==2'b00);
assign collision_srcB_tr0 = (srcB_q1==dest_q2) & wrcycl & (thread_q2==2'b00);

always @(*) begin
            case (thread_q1)
                2'b00 : begin     //thread 0
                            casex (srcA_q1)
                                14'b1xxxxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr0) ? resultout : prvt_2k_rddataA;    
                                14'bx1xxxxxxxxxxxx : rdSrcAdata = ROM_4k_rddataA;        
                                14'bxx1xxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr0) ? resultout : prvt_2k_rddataA;       
                                14'bxxx1xxxxxxxxxx : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataA;   
                                14'bxxxx1xxxxxxxxx : rdSrcAdata = global_F512_rddataA;   
                                14'bxxxxx1xxxxxxxx : rdSrcAdata = global_I256_rddataA;   
                                14'bxxxxxx1xxxxxxx : rdSrcAdata = private_F128_rddataA;  
                                
                               AR3_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : tr0_AR3;                      
                               AR2_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : tr0_AR2;                      
                               AR1_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : tr0_AR1;
                               AR0_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : tr0_AR0;
                                PC_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : {20'h00000, tr0_PC};
                                 PC_COPY : rdSrcAdata = (collision_srcA_tr0) ? resultout : {20'h00000, tr0_PC_COPY};
                                ST_ADDRS : rdSrcAdata = (thread_q1==thread_q2) ? tr0_STATUSq2 : tr0_STATUS;
                             SCHED_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : tr0_C_reg;                               
                            LPCNT1_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : {16'h0000, tr0_LPCNT1_nz, 3'b000, tr0_LPCNT1};
                            LPCNT0_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : {16'h0000, tr0_LPCNT0_nz, 3'b000, tr0_LPCNT0};
                             TIMER_ADDRS : rdSrcAdata = (collision_srcA_tr0) ? resultout : {12'h000, tr0_timer};                               
                               QOS_ADDRS : rdSrcAdata = {tr0_underflow_QOS, tr0_overflow_QOS, tr0_divby0_QOS, tr0_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcAdata = tr0_capt_dataA;
                                
                                14'h005x,
                                14'h004x : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataA;
                                14'b00000000xxxxxx : rdSrcAdata = (collision_srcA_tr0) ? resultout : prvt_rddataA;                                         
                                default  : rdSrcAdata = 32'h0000_0000;  
                            endcase
                        end
                        
                2'b01 : begin           //thread 1
                            casex (srcA_q1)
                                14'b1xxxxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr1) ? resultout : prvt_2k_rddataA;    
                                14'bx1xxxxxxxxxxxx : rdSrcAdata = ROM_4k_rddataA;        
                                14'bxx1xxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr1) ? resultout : prvt_2k_rddataA;       
                                14'bxxx1xxxxxxxxxx : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataA;   
                                14'bxxxx1xxxxxxxxx : rdSrcAdata = global_F512_rddataA;   
                                14'bxxxxx1xxxxxxxx : rdSrcAdata = global_I256_rddataA;   
                                14'bxxxxxx1xxxxxxx : rdSrcAdata = private_F128_rddataA;  
                                
                               AR3_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : tr1_AR3;                      
                               AR2_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : tr1_AR2;                      
                               AR1_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : tr1_AR1;
                               AR0_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : tr1_AR0;
                                PC_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : {20'h00000, tr1_PC};
                                 PC_COPY : rdSrcAdata = (collision_srcA_tr1) ? resultout : {20'h00000, tr1_PC_COPY};
                                ST_ADDRS : rdSrcAdata = (thread_q1==thread_q2) ? tr1_STATUSq2 : tr1_STATUS;
                             SCHED_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : tr1_C_reg;                               
                            LPCNT1_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : {16'h0000, tr1_LPCNT1_nz, 3'b000, tr1_LPCNT1};
                            LPCNT0_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : {16'h0000, tr1_LPCNT0_nz, 3'b000, tr1_LPCNT0};
                             TIMER_ADDRS : rdSrcAdata = (collision_srcA_tr1) ? resultout : {12'h000, tr1_timer};                               
                               QOS_ADDRS : rdSrcAdata = {tr1_underflow_QOS, tr1_overflow_QOS, tr1_divby0_QOS, tr1_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcAdata = tr1_capt_dataA;
                                
                                14'h005x,
                                14'h004x : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataA;
                                14'b00000000xxxxxx : rdSrcAdata = (collision_srcA_tr1) ? resultout : prvt_rddataA;                                         
                                default  : rdSrcAdata = 32'h0000_0000;  
                            endcase
                        end
                        
                2'b10 : begin     // thread 2
                            casex (srcA_q1)
                                14'b1xxxxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr2) ? resultout : prvt_2k_rddataA;    
                                14'bx1xxxxxxxxxxxx : rdSrcAdata = ROM_4k_rddataA;        
                                14'bxx1xxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr2) ? resultout : prvt_2k_rddataA;       
                                14'bxxx1xxxxxxxxxx : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataA;   
                                14'bxxxx1xxxxxxxxx : rdSrcAdata = global_F512_rddataA;   
                                14'bxxxxx1xxxxxxxx : rdSrcAdata = global_I256_rddataA;   
                                14'bxxxxxx1xxxxxxx : rdSrcAdata = private_F128_rddataA;  
                                
                               AR3_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : tr2_AR3;                      
                               AR2_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : tr2_AR2;                      
                               AR1_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : tr2_AR1;
                               AR0_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : tr2_AR0;
                                PC_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : {20'h00000, tr2_PC};
                                 PC_COPY : rdSrcAdata = (collision_srcA_tr2) ? resultout : {20'h00000, tr2_PC_COPY};
                                ST_ADDRS : rdSrcAdata = (thread_q1==thread_q2) ? tr2_STATUSq2 : tr2_STATUS;
                             SCHED_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : tr2_C_reg;                               
                            LPCNT1_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : {16'h0000, tr2_LPCNT1_nz, 3'b000, tr2_LPCNT1};
                            LPCNT0_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : {16'h0000, tr2_LPCNT0_nz, 3'b000, tr2_LPCNT0};
                             TIMER_ADDRS : rdSrcAdata = (collision_srcA_tr2) ? resultout : {12'h000, tr2_timer};                               
                               QOS_ADDRS : rdSrcAdata = {tr2_underflow_QOS, tr2_overflow_QOS, tr2_divby0_QOS, tr2_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcAdata = tr2_capt_dataA;
                                
                                14'h005x,
                                14'h004x : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataA;
                                14'b00000000xxxxxx : rdSrcAdata = (collision_srcA_tr2) ? resultout : prvt_rddataA;                                         
                                default  : rdSrcAdata = 32'h0000_0000;  
                            endcase
                        end
                        
                2'b11 : begin
                            casex (srcA_q1)
                                14'b1xxxxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr3) ? resultout : prvt_2k_rddataA;    
                                14'bx1xxxxxxxxxxxx : rdSrcAdata = ROM_4k_rddataA;        
                                14'bxx1xxxxxxxxxxx : rdSrcAdata = (collision_srcA_tr3) ? resultout : prvt_2k_rddataA;       
                                14'bxxx1xxxxxxxxxx : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataA;   
                                14'bxxxx1xxxxxxxxx : rdSrcAdata = global_F512_rddataA;   
                                14'bxxxxx1xxxxxxxx : rdSrcAdata = global_I256_rddataA;   
                                14'bxxxxxx1xxxxxxx : rdSrcAdata = private_F128_rddataA;  
                                
                               AR3_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : tr3_AR3;                      
                               AR2_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : tr3_AR2;                      
                               AR1_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : tr3_AR1;
                               AR0_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : tr3_AR0;
                                PC_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : {20'h00000, tr3_PC};
                                 PC_COPY : rdSrcAdata = (collision_srcA_tr3) ? resultout : {20'h00000, tr3_PC_COPY};
                                ST_ADDRS : rdSrcAdata = (thread_q1==thread_q2) ? tr3_STATUSq2 : tr3_STATUS;
                             SCHED_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : tr3_C_reg;                               
                            LPCNT1_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : {16'h0000, tr3_LPCNT1_nz, 3'b000, tr3_LPCNT1};
                            LPCNT0_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : {16'h0000, tr3_LPCNT0_nz, 3'b000, tr3_LPCNT0};
                             TIMER_ADDRS : rdSrcAdata = (collision_srcA_tr3) ? resultout : {12'h000, tr3_timer};                               
                               QOS_ADDRS : rdSrcAdata = {tr3_underflow_QOS, tr3_overflow_QOS, tr3_divby0_QOS, tr3_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcAdata = tr3_capt_dataA;
                                
                                14'h005x,
                                14'h004x : rdSrcAdata = ((srcA_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataA;
                                14'b00000000xxxxxx : rdSrcAdata = (collision_srcA_tr3) ? resultout : prvt_rddataA;                                         
                                default  : rdSrcAdata = 32'h0000_0000;  
                            endcase
                        end
            endcase                 
end    
 
always @(*) begin        
            case (thread_q1)
                2'b00 : begin     //thread 0
                            casex (srcB_q1)                                                            
                                14'b1xxxxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr0) ? resultout : prvt_2k_rddataB;    
                                14'bxx1xxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr0) ? resultout : prvt_2k_rddataB;       
                                14'bxxx1xxxxxxxxxx : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataB;   
                                14'bxxxx1xxxxxxxxx : rdSrcBdata = global_F512_rddataB;   
                                14'bxxxxx1xxxxxxxx : rdSrcBdata = global_I256_rddataB;   
                                14'bxxxxxx1xxxxxxx : rdSrcBdata = private_F128_rddataB;  
                                
                               AR3_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : tr0_AR3;                      
                               AR2_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : tr0_AR2;                      
                               AR1_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : tr0_AR1;
                               AR0_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : tr0_AR0;
                                PC_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : {20'h00000, tr0_PC};
                                 PC_COPY : rdSrcBdata = (collision_srcB_tr0) ? resultout : {20'h00000, tr0_PC_COPY};
                                ST_ADDRS : rdSrcBdata = (thread_q1==thread_q2) ? tr0_STATUSq2 : tr0_STATUS;
                             SCHED_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : tr0_C_reg;                               
                            LPCNT1_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : {16'h0000, tr0_LPCNT1_nz, 3'b000, tr0_LPCNT1};
                            LPCNT0_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : {16'h0000, tr0_LPCNT0_nz, 3'b000, tr0_LPCNT0};
                             TIMER_ADDRS : rdSrcBdata = (collision_srcB_tr0) ? resultout : {12'h000, tr0_timer};                               
                               QOS_ADDRS : rdSrcBdata = {tr0_underflow_QOS, tr0_overflow_QOS, tr0_divby0_QOS, tr0_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcBdata = tr0_capt_dataB;
                                
                                14'h005x,
                                14'h004x : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataB;
                                14'b00000000xxxxxx : rdSrcBdata = (collision_srcB_tr0) ? resultout : prvt_rddataB;                                         
                                default  : rdSrcBdata = 32'h0000_0000;  
                            endcase
                        end
                        
                2'b01 : begin           //thread 1
                            casex (srcB_q1)                            
                                14'b1xxxxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr1) ? resultout : prvt_2k_rddataB;    
                                14'bxx1xxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr1) ? resultout : prvt_2k_rddataB;       
                                14'bxxx1xxxxxxxxxx : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataB;   
                                14'bxxxx1xxxxxxxxx : rdSrcBdata = global_F512_rddataB;   
                                14'bxxxxx1xxxxxxxx : rdSrcBdata = global_I256_rddataB;   
                                14'bxxxxxx1xxxxxxx : rdSrcBdata = private_F128_rddataB;  
                                
                               AR3_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : tr1_AR3;                      
                               AR2_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : tr1_AR2;                      
                               AR1_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : tr1_AR1;
                               AR0_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : tr1_AR0;
                                PC_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : {20'h00000, tr1_PC};
                                 PC_COPY : rdSrcBdata = (collision_srcB_tr1) ? resultout : {20'h00000, tr1_PC_COPY};
                                ST_ADDRS : rdSrcBdata = (thread_q1==thread_q2) ? tr1_STATUSq2 : tr1_STATUS;
                             SCHED_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : tr1_C_reg;                               
                            LPCNT1_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : {16'h0000, tr1_LPCNT1_nz, 3'b000, tr1_LPCNT1};
                            LPCNT0_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : {16'h0000, tr1_LPCNT0_nz, 3'b000, tr1_LPCNT0};
                             TIMER_ADDRS : rdSrcBdata = (collision_srcB_tr1) ? resultout : {12'h000, tr1_timer};                               
                               QOS_ADDRS : rdSrcBdata = {tr1_underflow_QOS, tr1_overflow_QOS, tr1_divby0_QOS, tr1_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcBdata = tr1_capt_dataB;
                                
                                14'h005x,
                                14'h004x : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataB;
                                14'b00000000xxxxxx : rdSrcBdata = (collision_srcB_tr1) ? resultout : prvt_rddataB;                                         
                                default  : rdSrcBdata = 32'h0000_0000;  
                            endcase
                        end
                        
                2'b10 : begin     // thread 2
                            casex (srcB_q1)                            
                                14'b1xxxxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr2) ? resultout : prvt_2k_rddataB;    
                                14'bxx1xxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr2) ? resultout : prvt_2k_rddataB;       
                                14'bxxx1xxxxxxxxxx : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataB;   
                                14'bxxxx1xxxxxxxxx : rdSrcBdata = global_F512_rddataB;   
                                14'bxxxxx1xxxxxxxx : rdSrcBdata = global_I256_rddataB;   
                                14'bxxxxxx1xxxxxxx : rdSrcBdata = private_F128_rddataB;  
                                
                               AR3_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : tr2_AR3;                      
                               AR2_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : tr2_AR2;                      
                               AR1_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : tr2_AR1;
                               AR0_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : tr2_AR0;
                                PC_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : {20'h00000, tr2_PC};
                                 PC_COPY : rdSrcBdata = (collision_srcB_tr2) ? resultout : {20'h00000, tr2_PC_COPY};
                                ST_ADDRS : rdSrcBdata = (thread_q1==thread_q2) ? tr2_STATUSq2 : tr2_STATUS;
                             SCHED_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : tr2_C_reg;                               
                            LPCNT1_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : {16'h0000, tr2_LPCNT1_nz, 3'b000, tr2_LPCNT1};
                            LPCNT0_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : {16'h0000, tr2_LPCNT0_nz, 3'b000, tr2_LPCNT0};
                             TIMER_ADDRS : rdSrcBdata = (collision_srcB_tr2) ? resultout : {12'h000, tr2_timer};                               
                               QOS_ADDRS : rdSrcBdata = {tr2_underflow_QOS, tr2_overflow_QOS, tr2_divby0_QOS, tr2_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcBdata = tr2_capt_dataB;
                                
                                14'h005x,
                                14'h004x : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataB;
                                14'b00000000xxxxxx : rdSrcBdata = (collision_srcB_tr2) ? resultout : prvt_rddataB;                                         
                                default  : rdSrcBdata = 32'h0000_0000;  
                            endcase
                        end
                        
                2'b11 : begin
                            casex (srcB_q1)
                                14'b1xxxxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr3) ? resultout : prvt_2k_rddataB;    
                                14'bxx1xxxxxxxxxxx : rdSrcBdata = (collision_srcB_tr3) ? resultout : prvt_2k_rddataB;       
                                14'bxxx1xxxxxxxxxx : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_1024_rddataB;   
                                14'bxxxx1xxxxxxxxx : rdSrcBdata = global_F512_rddataB;   
                                14'bxxxxx1xxxxxxxx : rdSrcBdata = global_I256_rddataB;   
                                14'bxxxxxx1xxxxxxx : rdSrcBdata = private_F128_rddataB;  
                                
                               AR3_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : tr3_AR3;                      
                               AR2_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : tr3_AR2;                      
                               AR1_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : tr3_AR1;
                               AR0_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : tr3_AR0;
                                PC_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : {20'h00000, tr3_PC};
                                 PC_COPY : rdSrcBdata = (collision_srcB_tr3) ? resultout : {20'h00000, tr3_PC_COPY};
                                ST_ADDRS : rdSrcBdata = (thread_q1==thread_q2) ? tr3_STATUSq2 : tr3_STATUS;
                             SCHED_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : scheduler;      //global
                          SCHEDCMP_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : sched_cmp;
                              CREG_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : tr3_C_reg;                               
                            LPCNT1_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : {16'h0000, tr3_LPCNT1_nz, 3'b000, tr3_LPCNT1};
                            LPCNT0_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : {16'h0000, tr3_LPCNT0_nz, 3'b000, tr3_LPCNT0};
                             TIMER_ADDRS : rdSrcBdata = (collision_srcB_tr3) ? resultout : {12'h000, tr3_timer};                               
                               QOS_ADDRS : rdSrcBdata = {tr3_underflow_QOS, tr3_overflow_QOS, tr3_divby0_QOS, tr3_invalid_QOS};                               
                               
                                14'h0064,  //reserved for RPT counter
                                
                             CAPT3_ADDRS,
                             CAPT2_ADDRS,
                             CAPT1_ADDRS,
                             CAPT0_ADDRS : rdSrcBdata = tr3_capt_dataB;
                                
                                14'h005x,
                                14'h004x : rdSrcBdata = ((srcB_q1==dest_q2) & wrcycl) ? resultout : global_32_rddataB;
                                14'b00000000xxxxxx : rdSrcBdata = (collision_srcB_tr3) ? resultout : prvt_rddataB;                                         
                                default  : rdSrcBdata = 32'h0000_0000;  
                            endcase
                        end
            endcase
end    
    
always @(*)  begin     
    if (~|STATE[1:0]) begin 
        {Z_q2, C_q2, N_q2, V_q2} = {1'b1, 1'b0, 1'b0, 1'b0};
        resultout = 32'h00000000;
    end    
    else
        casex (opcode_q2)
            MOV_  : case (thread_q2)
                        2'b00 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = ~|wrsrcAdata;
                                    N_q2 = wrsrcAdata[31];
                                    C_q2 = tr0_C;
                                    V_q2 = tr0_V;
                                end 
                        2'b01 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = ~|wrsrcAdata;
                                    N_q2 = wrsrcAdata[31];
                                    C_q2 = tr1_C;
                                    V_q2 = tr1_V;
                                end 
                                   
                        2'b10 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = ~|wrsrcAdata;
                                    N_q2 = wrsrcAdata[31];
                                    C_q2 = tr2_C;
                                    V_q2 = tr2_V;
                                end 
                                   
                        2'b11 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = ~|wrsrcAdata;
                                    N_q2 = wrsrcAdata[31];
                                    C_q2 = tr3_C;
                                    V_q2 = tr3_V;
                                end
                    endcase                                                
                                
            OR_   : case (thread_q2)
                        2'b00 : begin
                                    resultout = wrsrcAdata | wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata | wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] | wrsrcBdata[31];
                                    C_q2 = tr0_C;
                                    V_q2 = tr0_V;
                                end 
                        2'b01 : begin
                                    resultout = wrsrcAdata | wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata | wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] | wrsrcBdata[31];
                                    C_q2 = tr1_C;
                                    V_q2 = tr1_V;
                                end 
                                   
                        2'b10 : begin
                                    resultout = wrsrcAdata | wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata | wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] | wrsrcBdata[31];
                                    C_q2 = tr2_C;
                                    V_q2 = tr2_V;
                                end 
                                   
                        2'b11 : begin
                                    resultout = wrsrcAdata | wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata | wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] | wrsrcBdata[31];
                                    C_q2 = tr3_C;
                                    V_q2 = tr3_V;
                                end
                    endcase                                                
                        
            XOR_  : case (thread_q2)
                        2'b00 : begin
                                    resultout = wrsrcAdata ^ wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata ^ wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] ^ wrsrcBdata[31];
                                    C_q2 = tr0_C;
                                    V_q2 = tr0_V;
                                end 
                        2'b01 : begin
                                    resultout = wrsrcAdata ^ wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata ^ wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] ^ wrsrcBdata[31];
                                    C_q2 = tr1_C;
                                    V_q2 = tr1_V;
                                end 
                                   
                        2'b10 : begin
                                    resultout = wrsrcAdata ^ wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata ^ wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] ^ wrsrcBdata[31];
                                    C_q2 = tr2_C;
                                    V_q2 = tr2_V;
                                end 
                                   
                        2'b11 : begin
                                    resultout = wrsrcAdata ^ wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata ^ wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] ^ wrsrcBdata[31];
                                    C_q2 = tr3_C;
                                    V_q2 = tr3_V;
                                end
                    endcase                                                

            AND_  : case (thread_q2)
                        2'b00 : begin
                                    resultout = wrsrcAdata & wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata & wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] & wrsrcBdata[31];
                                    C_q2 = tr0_C;
                                    V_q2 = tr0_V;
                                end 
                        2'b01 : begin
                                    resultout = wrsrcAdata & wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata & wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] & wrsrcBdata[31];
                                    C_q2 = tr1_C;
                                    V_q2 = tr1_V;
                                end 
                                   
                        2'b10 : begin
                                    resultout = wrsrcAdata & wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata & wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] & wrsrcBdata[31];
                                    C_q2 = tr2_C;
                                    V_q2 = tr2_V;
                                end 
                                   
                        2'b11 : begin
                                    resultout = wrsrcAdata & wrsrcBdata;
                                    Z_q2 = ~|(wrsrcAdata & wrsrcBdata);
                                    N_q2 = wrsrcAdata[31] & wrsrcBdata[31];
                                    C_q2 = tr3_C;
                                    V_q2 = tr3_V;
                                end
                    endcase                                                

            ADDC_,
             ADD_,
            SUBB_, 
             SUB_ : begin
                        resultout = adder_out;
                        Z_q2 = adder_ZO;
                        V_q2 = adder_OVO;
                        C_q2 = adder_CO;
                        N_q2 = adder_out[31];
                    end 
             MUL_ : case (thread_q2)
                        2'b00 : begin             
                                   resultout = wrsrcAdata[15:0] * wrsrcBdata[15:0];
                                   Z_q2 = ~|wrsrcAdata[15:0] | ~|wrsrcBdata[15:0];
                                   N_q2 = wrsrcAdata[15] ^ wrsrcBdata[15];
                                   C_q2 = tr0_C;
                                   V_q2 = tr0_V;
                                end   
                        2'b01 : begin             
                                   resultout = wrsrcAdata[15:0] * wrsrcBdata[15:0];
                                   Z_q2 = ~|wrsrcAdata[15:0] | ~|wrsrcBdata[15:0];
                                   N_q2 = wrsrcAdata[15] ^ wrsrcBdata[15];
                                   C_q2 = tr1_C;
                                   V_q2 = tr1_V;
                                end  
                        2'b10 : begin             
                                   resultout = wrsrcAdata[15:0] * wrsrcBdata[15:0];
                                   Z_q2 = ~|wrsrcAdata[15:0] | ~|wrsrcBdata[15:0];
                                   N_q2 = wrsrcAdata[15] ^ wrsrcBdata[15];
                                   C_q2 = tr2_C;
                                   V_q2 = tr2_V;
                                end   
                        2'b11 : begin             
                                   resultout = wrsrcAdata[15:0] * wrsrcBdata[15:0];
                                   Z_q2 = ~|wrsrcAdata[15:0] | ~|wrsrcBdata[15:0];
                                   N_q2 = wrsrcAdata[15] ^ wrsrcBdata[15];
                                   C_q2 = tr3_C;
                                   V_q2 = tr3_V;
                                end   
                    endcase                                    
                                                                                
             RCP_ : case (thread_q2)
                        2'b00 : begin              
                                   resultout = rcp_out;
                                   Z_q2 = 1'b0;
                                   N_q2 = rcp_out[31];
                                   C_q2 = tr0_C;
                                   V_q2 = tr0_V;
                                end
                        2'b01 : begin              
                                   resultout = rcp_out;
                                   Z_q2 = 1'b0;
                                   N_q2 = rcp_out[31];
                                   C_q2 = tr1_C;
                                   V_q2 = tr1_V;
                                end
                        2'b10 : begin              
                                   resultout = rcp_out;
                                   Z_q2 = 1'b0;
                                   N_q2 = rcp_out[31];
                                   C_q2 = tr2_C;
                                   V_q2 = tr2_V;
                                end
                        2'b11 : begin              
                                   resultout = rcp_out;
                                   Z_q2 = 1'b0;
                                   N_q2 = rcp_out[31];
                                   C_q2 = tr3_C;
                                   V_q2 = tr3_V;
                                end
                    endcase               

            SIN_  : case (thread_q2)
                        2'b00 : begin 
                                   resultout = sin_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = sin_out[31];
                                   C_q2 = tr0_C;
                                   V_q2 = tr0_V;
                                end
                        2'b01 : begin 
                                   resultout = sin_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = sin_out[31];
                                   C_q2 = tr1_C;
                                   V_q2 = tr1_V;
                                end
                        2'b10 : begin                                                               
                                   resultout = sin_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = sin_out[31];
                                   C_q2 = tr2_C;
                                   V_q2 = tr2_V;
                                end
                        2'b11 : begin              
                                   resultout = sin_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = sin_out[31];
                                   C_q2 = tr3_C;
                                   V_q2 = tr3_V;
                                end
                    endcase                                                   

            COS_  : case (thread_q2)
                        2'b00 : begin              
                                   resultout = cos_out;
                                   Z_q2 = &wrsrcAdata;
                                   N_q2 = cos_out[31];
                                   C_q2 = tr0_C;
                                   V_q2 = tr0_V;
                                end
                        2'b01 : begin              
                                   resultout = cos_out;
                                   Z_q2 = &wrsrcAdata;
                                   N_q2 = cos_out[31];
                                   C_q2 = tr1_C;
                                   V_q2 = tr1_V;
                                end
                        2'b10 : begin              
                                   resultout = cos_out;
                                   Z_q2 = &wrsrcAdata;
                                   N_q2 = cos_out[31];
                                   C_q2 = tr2_C;
                                   V_q2 = tr2_V;
                                end
                        2'b11 : begin              
                                   resultout = cos_out;
                                   Z_q2 = &wrsrcAdata;
                                   N_q2 = cos_out[31];
                                   C_q2 = tr3_C;
                                   V_q2 = tr3_V;
                                end
                                
                    endcase               

             TAN_ : case (thread_q2)
                        2'b00 : begin              
                                   resultout = tan_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = tan_out[31];
                                   C_q2 = tr0_C;
                                   V_q2 = tr0_V;
                                end
                        2'b01 : begin              
                                   resultout = tan_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = tan_out[31];
                                   C_q2 = tr1_C;
                                   V_q2 = tr1_V;
                                end
                        2'b10 : begin              
                                   resultout = tan_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = tan_out[31];
                                   C_q2 = tr2_C;
                                   V_q2 = tr2_V;
                                end
                        2'b11 : begin              
                                   resultout = tan_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = tan_out[31];
                                   C_q2 = tr3_C;
                                   V_q2 = tr3_V;
                                end
                    endcase               
                                                              
            COT_  : case (thread_q2)
                        2'b00 : begin              
                                   resultout = cot_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = cot_out[31];
                                   C_q2 = tr0_C;
                                   V_q2 = tr0_V;
                                end
                        2'b01 : begin              
                                   resultout = cot_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = cot_out[31];
                                   C_q2 = tr1_C;
                                   V_q2 = tr1_V;
                                end
                        2'b10 : begin              
                                   resultout = cot_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = cot_out[31];
                                   C_q2 = tr2_C;
                                   V_q2 = tr2_V;
                                end
                        2'b11 : begin              
                                   resultout = cot_out;
                                   Z_q2 = ~|wrsrcAdata;
                                   N_q2 = cot_out[31];
                                   C_q2 = tr3_C;
                                   V_q2 = tr3_V;
                                end
                    endcase               
                                                             
            SHFT_ : case (shiftype)
                        LEFT_  : case (thread_q2)
                                     2'b00 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 C_q2 = tr0_C;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 C_q2 = tr1_C;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 C_q2 = tr2_C;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 C_q2 = tr3_C;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase                                         

                        LSL_   : case (thread_q2)
                                     2'b00 : begin
                                                 {C_q2, resultout} = {wrsrcAdata, 1'b0} << shiftamount1;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 {C_q2, resultout} = {wrsrcAdata, 1'b0} << shiftamount1;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 {C_q2, resultout} = {wrsrcAdata, 1'b0} << shiftamount1;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 {C_q2, resultout} = {wrsrcAdata, 1'b0} << shiftamount1;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase                                         

                        ASL_   : case (thread_q2)
                                     2'b00 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 C_q2 = tr0_C;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 C_q2 = tr1_C;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 C_q2 = tr2_C;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 resultout = wrsrcAdata << shiftamount1;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 C_q2 = tr3_C;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase                                         

                        ROL_   : case (thread_q2)                                        
                                     2'b00 : begin
                                                 resultout =  brlshft_ROL;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 C_q2 = tr0_C;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 resultout =  brlshft_ROL;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 C_q2 = tr1_C;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 resultout =  brlshft_ROL;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 C_q2 = tr2_C;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 resultout =  brlshft_ROL;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 C_q2 = tr3_C;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase
                                                                                                                                     
                        RIGHT_ : case (thread_q2)
                                     2'b00 : begin
                                                 resultout = wrsrcAdata >> shiftamount1;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 C_q2 = tr0_C;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 resultout = wrsrcAdata >> shiftamount1;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 C_q2 = tr1_C;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 resultout = wrsrcAdata >> shiftamount1;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 C_q2 = tr2_C;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 resultout = wrsrcAdata >> shiftamount1;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 C_q2 = tr3_C;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase 

                        LSR_   : case (thread_q2)
                                     2'b00 : begin
                                                 {resultout, C_q2} = {1'b0, wrsrcAdata} >> shiftamount1;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 {resultout, C_q2} = {1'b0, wrsrcAdata} >> shiftamount1;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 {resultout, C_q2} = {1'b0, wrsrcAdata} >> shiftamount1;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 {resultout, C_q2} = {1'b0, wrsrcAdata} >> shiftamount1;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase 

                        ASR_   : case (thread_q2)
                                     2'b00 : begin
                                                 {shiftbucket, resultout[31:0]} = {sbits, wrsrcAdata[31:1]} >> shiftamount1;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 C_q2 = tr0_C;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 {shiftbucket, resultout[31:0]} = {sbits, wrsrcAdata[31:1]} >> shiftamount1;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 C_q2 = tr1_C;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 {shiftbucket, resultout[31:0]} = {sbits, wrsrcAdata[31:1]} >> shiftamount1;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 C_q2 = tr2_C;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 {shiftbucket, resultout[31:0]} = {sbits, wrsrcAdata[31:1]} >> shiftamount1;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 C_q2 = tr3_C;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase
                                  
                        ROR_   : case (thread_q2)
                                     2'b00 : begin
                                                 resultout =  brlshft_ROR;
                                                 Z_q2 = tr0_Z;
                                                 N_q2 = tr0_N;
                                                 C_q2 = tr0_C;
                                                 V_q2 = tr0_V;
                                             end
                                     2'b01 : begin
                                                 resultout =  brlshft_ROR;
                                                 Z_q2 = tr1_Z;
                                                 N_q2 = tr1_N;
                                                 C_q2 = tr1_C;
                                                 V_q2 = tr1_V;
                                             end
                                     2'b10 : begin
                                                 resultout =  brlshft_ROR;
                                                 Z_q2 = tr2_Z;
                                                 N_q2 = tr2_N;
                                                 C_q2 = tr2_C;
                                                 V_q2 = tr2_V;
                                             end
                                     2'b11 : begin
                                                 resultout =  brlshft_ROR;
                                                 Z_q2 = tr3_Z;
                                                 N_q2 = tr3_N;
                                                 C_q2 = tr3_C;
                                                 V_q2 = tr3_V;
                                             end
                                 endcase 
                    endcase
                      
            BTB_  : case (thread_q2)
                        2'b00 : begin
                                    resultout = wrsrcBdata;
                                    Z_q2 = tr0_Z;
                                    N_q2 = tr0_N;
                                    C_q2 = tr0_C;
                                    V_q2 = tr0_V;
                                end
                        2'b01 : begin
                                    resultout = wrsrcBdata;
                                    Z_q2 = tr1_Z;
                                    N_q2 = tr1_N;
                                    C_q2 = tr1_C;
                                    V_q2 = tr1_V;
                                end
                        2'b10 : begin
                                    resultout = wrsrcBdata;
                                    Z_q2 = tr2_Z;
                                    N_q2 = tr2_N;
                                    C_q2 = tr2_C;
                                    V_q2 = tr2_V;
                                end
                        2'b11 : begin
                                    resultout = wrsrcBdata;
                                    Z_q2 = tr3_Z;
                                    N_q2 = tr3_N;
                                    C_q2 = tr3_C;
                                    V_q2 = tr3_V;
                                end
                    endcase 
                                           
          default : case (thread_q2)
                        2'b00 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = tr0_Z;
                                    N_q2 = tr0_N;
                                    C_q2 = tr0_C;
                                    V_q2 = tr0_V;
                                end
                        2'b01 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = tr1_Z;
                                    N_q2 = tr1_N;
                                    C_q2 = tr1_C;
                                    V_q2 = tr1_V;
                                end
                        2'b10 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = tr2_Z;
                                    N_q2 = tr2_N;
                                    C_q2 = tr2_C;
                                    V_q2 = tr2_V;
                                end
                        2'b11 : begin
                                    resultout = wrsrcAdata;
                                    Z_q2 = tr3_Z;
                                    N_q2 = tr3_N;
                                    C_q2 = tr3_C;
                                    V_q2 = tr3_V;
                                end
                    endcase 
        endcase 
end 


always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
        REPEAT <= 11'h000;
    end
    else if (( &constn && (OPdest==RPT_ADDRS[7:0])) && ~RPT_not_z && ~discont) REPEAT[10:0] <= P_DATAi[10:0]; 
    else if ((~|constn && (OPdest==RPT_ADDRS[7:0])) && ~RPT_not_z && ~discont && &OPsrcA[6:4] && ~OPsrcA[3:2]) begin
        casex(OPsrcA)
            8'h74,
            8'h78,
            8'h7C : case(newthreadq)
                        2'b00 : REPEAT[10:0] <= tr0_AR0[10:0];
                        2'b01 : REPEAT[10:0] <= tr1_AR0[10:0];
                        2'b10 : REPEAT[10:0] <= tr2_AR0[10:0];
                        2'b11 : REPEAT[10:0] <= tr3_AR0[10:0];
                    endcase    
            8'h75,
            8'h79,
            8'h7D : case(newthreadq)
                        2'b00 : REPEAT[10:0] <= tr0_AR1[10:0];
                        2'b01 : REPEAT[10:0] <= tr1_AR1[10:0];
                        2'b10 : REPEAT[10:0] <= tr2_AR1[10:0];
                        2'b11 : REPEAT[10:0] <= tr3_AR1[10:0];
                    endcase    
            8'h76,
            8'h7A,
            8'h7E : case(newthreadq)
                        2'b00 : REPEAT[10:0] <= tr0_AR2[10:0];
                        2'b01 : REPEAT[10:0] <= tr1_AR2[10:0];
                        2'b10 : REPEAT[10:0] <= tr2_AR2[10:0];
                        2'b11 : REPEAT[10:0] <= tr3_AR2[10:0];
                    endcase    
            8'h77,
            8'h7B,
            8'h7F : case(newthreadq)
                        2'b00 : REPEAT[10:0] <= tr0_AR3[10:0];
                        2'b01 : REPEAT[10:0] <= tr1_AR3[10:0];
                        2'b10 : REPEAT[10:0] <= tr2_AR3[10:0];
                        2'b11 : REPEAT[10:0] <= tr3_AR3[10:0];
                    endcase
        endcase                
    end 
    else if (|REPEAT[10:0]) REPEAT[10:0] <= REPEAT[10:0] - 1'b1;
end   
 
always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
        tr3_LPCNT1 <= 12'h000;
        tr3_LPCNT0 <= 12'h000;
        tr2_LPCNT1 <= 12'h000;
        tr2_LPCNT0 <= 12'h000;
        tr1_LPCNT1 <= 12'h000;
        tr1_LPCNT0 <= 12'h000;
        tr0_LPCNT1 <= 12'h000;
        tr0_LPCNT0 <= 12'h000;
    end
        
    else begin
       if ((dest_q2==LPCNT0_ADDRS) && (thread_q2==2'b00) && wrcycl) tr0_LPCNT0 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT0_ADDRS) && (thread_q2==2'b00) && |tr0_LPCNT0 && ~pipe_flush) tr0_LPCNT0 <= tr0_LPCNT0_dec;

       if ((dest_q2==LPCNT0_ADDRS) && (thread_q2==2'b01) && wrcycl) tr1_LPCNT0 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT0_ADDRS) && (thread_q2==2'b01) && |tr1_LPCNT0 && ~pipe_flush) tr1_LPCNT0 <= tr1_LPCNT0_dec;
       
       if ((dest_q2==LPCNT0_ADDRS) && (thread_q2==2'b10) && wrcycl) tr2_LPCNT0 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT0_ADDRS) && (thread_q2==2'b10) && |tr2_LPCNT0 && ~pipe_flush) tr2_LPCNT0 <= tr2_LPCNT0_dec;
       
       if ((dest_q2==LPCNT0_ADDRS) && (thread_q2==2'b11) && wrcycl) tr3_LPCNT0 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT0_ADDRS) && (thread_q2==2'b11) && |tr3_LPCNT0 && ~pipe_flush) tr3_LPCNT0 <= tr3_LPCNT0_dec;


       if ((dest_q2==LPCNT1_ADDRS) && (thread_q2==2'b00) && wrcycl) tr0_LPCNT1 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT1_ADDRS) && (thread_q2==2'b00) && |tr0_LPCNT1 && ~pipe_flush) tr0_LPCNT1 <= tr0_LPCNT1_dec;

       if ((dest_q2==LPCNT1_ADDRS) && (thread_q2==2'b01) && wrcycl) tr1_LPCNT1 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT1_ADDRS) && (thread_q2==2'b01) && |tr1_LPCNT1 && ~pipe_flush) tr1_LPCNT1 <= tr1_LPCNT1_dec;
       
       if ((dest_q2==LPCNT1_ADDRS) && (thread_q2==2'b10) && wrcycl) tr2_LPCNT1 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT1_ADDRS) && (thread_q2==2'b10) && |tr2_LPCNT1 && ~pipe_flush) tr2_LPCNT1 <= tr2_LPCNT1_dec;
       
       if ((dest_q2==LPCNT1_ADDRS) && (thread_q2==2'b11) && wrcycl) tr3_LPCNT1 <= resultout[11:0];
       else if ((opcode_q2==BTB_) && (srcB_q2==LPCNT1_ADDRS) && (thread_q2==2'b11) && |tr3_LPCNT1 && ~pipe_flush) tr3_LPCNT1 <= tr3_LPCNT1_dec;
    end   
end            

// FP Quality Of Service meters tr3
always @(posedge CLK or posedge tr3_done) begin
    if (tr3_done) begin
        {tr3_underflow_QOS, tr3_overflow_QOS, tr3_divby0_QOS, tr3_invalid_QOS} <= 32'h0000_0000;
    end
    else begin
        if ((dest_q2==QOS_ADDRS) && (thread_q2==2'b11) && wrcycl) {tr3_underflow_QOS, tr3_overflow_QOS, tr3_divby0_QOS, tr3_invalid_QOS} <= resultout;
        else begin
            if (tr3_invalid && ~&tr3_invalid_QOS)     tr3_invalid_QOS   <= tr3_invalid_QOS + 1'b1;
            if (tr3_divby0 && ~&tr3_divby0_QOS)       tr3_divby0_QOS    <= tr3_divby0_QOS + 1'b1;
            if (tr3_overflow && ~&tr3_overflow_QOS)   tr3_overflow_QOS  <= tr3_overflow_QOS + 1'b1;
            if (tr3_underflow && ~&tr3_underflow_QOS) tr3_underflow_QOS <= tr3_underflow_QOS + 1'b1;
        end
    end
end    
// FP Quality Of Service meters tr2
always @(posedge CLK or posedge tr2_done) begin
    if (tr2_done) begin
        {tr2_underflow_QOS, tr2_overflow_QOS, tr2_divby0_QOS, tr2_invalid_QOS} <= 32'h0000_0000;
    end
    else begin
        if ((dest_q2==QOS_ADDRS) && (thread_q2==2'b11) && wrcycl) {tr2_underflow_QOS, tr2_overflow_QOS, tr2_divby0_QOS, tr2_invalid_QOS} <= resultout;
        else begin
            if (tr2_invalid && ~&tr2_invalid_QOS)     tr2_invalid_QOS   <= tr2_invalid_QOS + 1'b1;
            if (tr2_divby0 && ~&tr2_divby0_QOS)       tr2_divby0_QOS    <= tr2_divby0_QOS + 1'b1;
            if (tr2_overflow && ~&tr2_overflow_QOS)   tr2_overflow_QOS  <= tr2_overflow_QOS + 1'b1;
            if (tr2_underflow && ~&tr2_underflow_QOS) tr2_underflow_QOS <= tr2_underflow_QOS + 1'b1;
        end
    end
end    
// FP Quality Of Service meters tr1
always @(posedge CLK or posedge tr1_done) begin
    if (tr1_done) begin
        {tr1_underflow_QOS, tr1_overflow_QOS, tr1_divby0_QOS, tr1_invalid_QOS} <= 32'h0000_0000;
    end
    else begin
        if ((dest_q2==QOS_ADDRS) && (thread_q2==2'b11) && wrcycl) {tr1_underflow_QOS, tr1_overflow_QOS, tr1_divby0_QOS, tr1_invalid_QOS} <= resultout;
        else begin
            if (tr1_invalid && ~&tr1_invalid_QOS)     tr1_invalid_QOS   <= tr1_invalid_QOS + 1'b1;
            if (tr1_divby0 && ~&tr1_divby0_QOS)       tr1_divby0_QOS    <= tr1_divby0_QOS + 1'b1;
            if (tr1_overflow && ~&tr1_overflow_QOS)   tr1_overflow_QOS  <= tr1_overflow_QOS + 1'b1;
            if (tr1_underflow && ~&tr1_underflow_QOS) tr1_underflow_QOS <= tr1_underflow_QOS + 1'b1;
        end
    end
end    
// FP Quality Of Service meters tr0
always @(posedge CLK or posedge tr0_done) begin
    if (tr0_done) begin
        {tr0_underflow_QOS, tr0_overflow_QOS, tr0_divby0_QOS, tr0_invalid_QOS} <= 32'h0000_0000;
    end
    else begin
        if ((dest_q2==QOS_ADDRS) && (thread_q2==2'b11) && wrcycl) {tr0_underflow_QOS, tr0_overflow_QOS, tr0_divby0_QOS, tr0_invalid_QOS} <= resultout;
        else begin
            if (tr0_invalid && ~&tr0_invalid_QOS)     tr0_invalid_QOS   <= tr0_invalid_QOS + 1'b1;
            if (tr0_divby0 && ~&tr0_divby0_QOS)       tr0_divby0_QOS    <= tr0_divby0_QOS + 1'b1;
            if (tr0_overflow && ~&tr0_overflow_QOS)   tr0_overflow_QOS  <= tr0_overflow_QOS + 1'b1;
            if (tr0_underflow && ~&tr0_underflow_QOS) tr0_underflow_QOS <= tr0_underflow_QOS + 1'b1;
        end
    end
end    

reg tr3_ld_vector_q1;
reg tr3_ld_vector_q2;
reg tr3_ld_vector_q3;
   
reg tr2_ld_vector_q1;
reg tr2_ld_vector_q2;
reg tr2_ld_vector_q3;  

reg tr1_ld_vector_q1;
reg tr1_ld_vector_q2;
reg tr1_ld_vector_q3;   
 
reg tr0_ld_vector_q1;
reg tr0_ld_vector_q2;
reg tr0_ld_vector_q3;   

always @(posedge CLK or posedge RESET) begin                                                                     
    if (RESET) begin                                                                                             
        PC <= 12'h100;                                                                                                         
        // state 1 fetch                                                                                         
        thread_q1 <= 2'b00; 
        pc_q1     <= 12'h100;                                                                               
        constn_q1 <= 2'b00;         // 00 = no const lookup, 10 = const/read table (srcA), 01 = 8-bit immediate (srcB), 11 = 16-bit immediate                
        opcode_q1 <= 4'b0000;                                                                                  
        srcA_q1   <= 14'h0000;                                                                                
        srcB_q1   <= 14'h0000;                                                                                
        OPdest_q1 <= 8'h00;
        OPsrcA_q1 <= 8'h00;
        OPsrcB_q1 <= 8'h00;
        
        round_mode_q1 <= 2'b00;

        // state2 read
        thread_q2 <= 2'b00;
        pc_q2     <= 12'h100;
        opcode_q2 <= 4'b0000;
        srcA_q2   <= 14'h0000;                                                                                
        srcB_q2   <= 14'h0000;
        OPdest_q2 <= 8'h00;
        OPsrcA_q2 <= 8'h00;        

        tr3_AR3 <= 32'h01_01_0000;
        tr3_AR2 <= 32'h01_01_0000;
        tr3_AR1 <= 32'h01_01_0000;
        tr3_AR0 <= 32'h01_01_0003;   //thread self-ID on RESET (hint: copy this into private RAM during init sequence to preserve thread self-identification)

        tr2_AR3 <= 32'h01_01_0000;
        tr2_AR2 <= 32'h01_01_0000;
        tr2_AR1 <= 32'h01_01_0000;
        tr2_AR0 <= 32'h01_01_0002;   //thread self-ID on RESET (hint: copy this into private RAM during init sequence to preserve thread self-identification)

        tr1_AR3 <= 32'h01_01_0000;
        tr1_AR2 <= 32'h01_01_0000;
        tr1_AR1 <= 32'h01_01_0000;
        tr1_AR0 <= 32'h01_01_0001;   //thread self-ID on RESET (hint: copy this into private RAM during init sequence to preserve thread self-identification)

        tr0_AR3 <= 32'h01_01_0000;
        tr0_AR2 <= 32'h01_01_0000;
        tr0_AR1 <= 32'h01_01_0000;
        tr0_AR0 <= 32'h01_01_0000;   //thread self-ID on RESET (hint: copy this into private RAM during init sequence to preserve thread self-identification)

        tr3_PC <= 12'h100;
        tr2_PC <= 12'h100;
        tr1_PC <= 12'h100;
        tr0_PC <= 12'h100;
        
        tr3_PC_COPY <= 12'h100;
        tr2_PC_COPY <= 12'h100;
        tr1_PC_COPY <= 12'h100;
        tr0_PC_COPY <= 12'h100;
        
        tr3_timer <= 20'h00000;
        tr2_timer <= 20'h00000; 
        tr1_timer <= 20'h00000; 
        tr0_timer <= 20'h00000; 

        tr3_timercmpr <= 20'h00000;
        tr2_timercmpr <= 20'h00000; 
        tr1_timercmpr <= 20'h00000; 
        tr0_timercmpr <= 20'h00000; 
        
        tr3_Z <= 1'b0;
        tr2_Z <= 1'b0;
        tr1_Z <= 1'b0;
        tr0_Z <= 1'b0;

        tr3_C <= 1'b0;
        tr2_C <= 1'b0;
        tr1_C <= 1'b0;
        tr0_C <= 1'b0;

        tr3_N <= 1'b0;
        tr2_N <= 1'b0;
        tr1_N <= 1'b0;
        tr0_N <= 1'b0;

        tr3_V <= 1'b0;
        tr2_V <= 1'b0;
        tr1_V <= 1'b0;
        tr0_V <= 1'b0;
        
        tr3_IRQ_IE <= 1'b0;
        tr2_IRQ_IE <= 1'b0;
        tr1_IRQ_IE <= 1'b0;
        tr0_IRQ_IE <= 1'b0;
        
        tr3_done   <= 1'b1;
        tr2_done   <= 1'b1;
        tr1_done   <= 1'b1;
        tr0_done   <= 1'b1;                                               
        
        tr3_locked <= 1'b0;                                               
        tr2_locked <= 1'b0;                                               
        tr1_locked <= 1'b0;                                               
        tr0_locked <= 1'b0;                                               
                                                                          
        tr3_invalid_flag <= 1'b0;
        tr2_invalid_flag <= 1'b0;
        tr1_invalid_flag <= 1'b0;
        tr0_invalid_flag <= 1'b0;
        
        tr3_divby0_flag <= 1'b0;
        tr2_divby0_flag <= 1'b0;
        tr1_divby0_flag <= 1'b0;
        tr0_divby0_flag <= 1'b0;
        
        tr3_overflow_flag <= 1'b0;
        tr2_overflow_flag <= 1'b0;
        tr1_overflow_flag <= 1'b0;
        tr0_overflow_flag <= 1'b0;
        
        tr3_underflow_flag <= 1'b0;
        tr2_underflow_flag <= 1'b0;
        tr1_underflow_flag <= 1'b0;
        tr0_underflow_flag <= 1'b0;

        tr3_inexact_flag <= 1'b0;
        tr2_inexact_flag <= 1'b0;
        tr1_inexact_flag <= 1'b0;
        tr0_inexact_flag <= 1'b0;
        
        tr3_alt_inv_handl <= 1'b0;
        tr2_alt_inv_handl <= 1'b0;
        tr1_alt_inv_handl <= 1'b0;
        tr0_alt_inv_handl <= 1'b0;
        
        tr3_alt_div0_handl <= 1'b0;
        tr2_alt_div0_handl <= 1'b0;
        tr1_alt_div0_handl <= 1'b0;
        tr0_alt_div0_handl <= 1'b0;
        
        tr3_alt_ovfl_handl <= 1'b0;
        tr2_alt_ovfl_handl <= 1'b0;
        tr1_alt_ovfl_handl <= 1'b0;
        tr0_alt_ovfl_handl <= 1'b0;
        
        tr3_alt_unfl_handl <= 1'b0;
        tr2_alt_unfl_handl <= 1'b0;
        tr1_alt_unfl_handl <= 1'b0;
        tr0_alt_unfl_handl <= 1'b0;

        tr3_alt_nxact_handl <= 1'b0;
        tr2_alt_nxact_handl <= 1'b0;
        tr1_alt_nxact_handl <= 1'b0;
        tr0_alt_nxact_handl <= 1'b0;
        
        tr3_alt_del_nxact <= 1'b0;
        tr2_alt_del_nxact <= 1'b0;
        tr1_alt_del_nxact <= 1'b0;
        tr0_alt_del_nxact <= 1'b0;
        
        tr3_alt_del_unfl <= 1'b0;
        tr2_alt_del_unfl <= 1'b0;
        tr1_alt_del_unfl <= 1'b0;
        tr0_alt_del_unfl <= 1'b0;
        
        tr3_alt_del_ovfl <= 1'b0;
        tr2_alt_del_ovfl <= 1'b0;
        tr1_alt_del_ovfl <= 1'b0;
        tr0_alt_del_ovfl <= 1'b0;
        
        tr3_alt_del_div0 <= 1'b0;
        tr2_alt_del_div0 <= 1'b0;
        tr1_alt_del_div0 <= 1'b0;
        tr0_alt_del_div0 <= 1'b0;
        
        tr3_alt_del_inv <= 1'b0; 
        tr2_alt_del_inv <= 1'b0; 
        tr1_alt_del_inv <= 1'b0; 
        tr0_alt_del_inv <= 1'b0; 

        tr0_C_reg <= 32'h00000000;
        tr1_C_reg <= 32'h00000000;
        tr2_C_reg <= 32'h00000000;
        tr3_C_reg <= 32'h00000000;
    
        STATE <= 3'b100;
        
        wrsrcAdata <= 32'h00000000;
        wrsrcBdata <= 32'h00000000; 
        
        newthreadq <= 2'b00;

        scheduler <= 32'h04040404;     //interleave threads 0-3
        sched_cmp <= 32'h04040404;     //interleave threads 0-3

        sched_state <= 4'b0001;
        pipe_flush_tr0 <= 2'b00;
        pipe_flush_tr1 <= 2'b00;
        pipe_flush_tr2 <= 2'b00;
        pipe_flush_tr3 <= 2'b00;
        
        tr3_ld_vector_q1 <= 1'b0;
        tr3_ld_vector_q2 <= 1'b0;
        tr3_ld_vector_q3 <= 1'b0;
        
        tr2_ld_vector_q1 <= 1'b0;
        tr2_ld_vector_q2 <= 1'b0;
        tr2_ld_vector_q3 <= 1'b0;
        
        tr1_ld_vector_q1 <= 1'b0;
        tr1_ld_vector_q2 <= 1'b0;
        tr1_ld_vector_q3 <= 1'b0;
        
        tr0_ld_vector_q1 <= 1'b0;
        tr0_ld_vector_q2 <= 1'b0;
        tr0_ld_vector_q3 <= 1'b0;
                
        fp_ready_q2 <= 1'b0;
        fp_sel_q2 <= 1'b0;
    end    
    else begin
        PC <= pre_PC;
////////////////////////////////////////////////////////////

        // if anything that causes a PC discontinuity is detected (about to occur), 
        // then flush instr pipe (disable write) for next 2 clocks, but only if same thread for such clocks 
        
        pipe_flush_tr0[0] <= discont & (thread_q2==thread_q1) & (thread_q2==2'b00);
        pipe_flush_tr1[0] <= discont & (thread_q2==thread_q1) & (thread_q2==2'b01);
        pipe_flush_tr2[0] <= discont & (thread_q2==thread_q1) & (thread_q2==2'b10);
        pipe_flush_tr3[0] <= discont & (thread_q2==thread_q1) & (thread_q2==2'b11);
        
        pipe_flush_tr0[1] <= pipe_flush_tr0[0] & (thread_q2==2'b00);
        pipe_flush_tr1[1] <= pipe_flush_tr1[0] & (thread_q2==2'b01);
        pipe_flush_tr2[1] <= pipe_flush_tr2[0] & (thread_q2==2'b10);
        pipe_flush_tr3[1] <= pipe_flush_tr3[0] & (thread_q2==2'b11);

        tr3_ld_vector_q1 <= tr3_ld_vector;
        tr3_ld_vector_q2 <= tr3_ld_vector_q1;
        tr3_ld_vector_q3 <= tr3_ld_vector_q2;  
                         
        tr2_ld_vector_q1 <= tr2_ld_vector;
        tr2_ld_vector_q2 <= tr2_ld_vector_q1;
        tr2_ld_vector_q3 <= tr2_ld_vector_q2;  

        tr1_ld_vector_q1 <= tr1_ld_vector;
        tr1_ld_vector_q2 <= tr1_ld_vector_q1;
        tr1_ld_vector_q3 <= tr1_ld_vector_q2;  
 
        tr0_ld_vector_q1 <= tr0_ld_vector;
        tr0_ld_vector_q2 <= tr0_ld_vector_q1;
        tr0_ld_vector_q3 <= tr0_ld_vector_q2;  

    ///////////////////// thread 0 PC /////////////////
        if (tr0_ld_vector) begin
            tr0_PC <= tr0_vector;
            if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b00) && ~|pipe_flush_tr0) tr0_PC_COPY <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};
            else if ((dest_q2 == PC_ADDRS) && wrcycl) tr0_PC_COPY = resultout;
            else tr0_PC_COPY = pc_q2 + 1'b1; 
        end   
        else if (tr0_ld_vector_q3) tr0_PC <= resultout;
        else if (tr0_rewind_PC) begin
            tr0_PC <= pc_q2;
            tr0_PC_COPY <= pc_q2 + 1'b1; 
        end 
        else if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b00)) begin            
            tr0_PC <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};             
            tr0_PC_COPY <= pc_q2 + 1'b1; 
        end         
        else if ((dest_q2==PC_ADDRS) && (thread_q2==2'b00) && wrcycl) begin
            tr0_PC <= resultout[11:0];                       
            if (~((pc_q2[11:2]==10'b0001_0000_00) && (dest_q2==PC_ADDRS))) tr0_PC_COPY <= pc_q2 + 1'b1;  //don't copy PC if interrupt vector fetch
        end      
        else if ((newthreadq==2'b00)) tr0_PC <= RPT_not_z ? tr0_PC : next_PC;   

    ///////////////////// thread 1 PC /////////////////
        if (tr1_ld_vector) begin
            tr1_PC <= tr1_vector;
            if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b01) && ~|pipe_flush_tr1) tr1_PC_COPY <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};
            else if ((dest_q2 == PC_ADDRS) && wrcycl) tr1_PC_COPY = resultout;
            else tr1_PC_COPY = pc_q2 + 1'b1; 
        end   
        else if (tr1_ld_vector_q3) tr1_PC <= resultout;
        else if (tr1_rewind_PC) begin
            tr1_PC <= pc_q2;
            tr1_PC_COPY <= pc_q2 + 1'b1; 
        end 
        else if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b01)) begin            
            tr1_PC <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};             
            tr1_PC_COPY <= pc_q2 + 1'b1; 
        end         
        else if ((dest_q2==PC_ADDRS) && (thread_q2==2'b01) && wrcycl) begin
            tr1_PC <= resultout[11:0];                       
            if (~((pc_q2[11:2]==10'b0001_0000_00) && (dest_q2==PC_ADDRS))) tr1_PC_COPY <= pc_q2 + 1'b1;  //don't copy PC if interrupt vector fetch
        end      
        else if ((newthreadq==2'b01)) tr1_PC <= RPT_not_z ? tr1_PC : next_PC;   

    ///////////////////// thread 2 PC /////////////////
        if (tr2_ld_vector) begin
            tr2_PC <= tr2_vector;
            if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b10) && ~|pipe_flush_tr2) tr2_PC_COPY <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};
            else if ((dest_q2 == PC_ADDRS) && wrcycl) tr2_PC_COPY = resultout;
            else tr2_PC_COPY = pc_q2 + 1'b1; 
        end   
        else if (tr2_ld_vector_q3) tr2_PC <= resultout;
        else if (tr2_rewind_PC) begin
            tr2_PC <= pc_q2;
            tr2_PC_COPY <= pc_q2 + 1'b1; 
        end 
        else if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b10)) begin            
            tr2_PC <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};             
            tr2_PC_COPY <= pc_q2 + 1'b1; 
        end         
        else if ((dest_q2==PC_ADDRS) && (thread_q2==2'b10) && wrcycl) begin
            tr2_PC <= resultout[11:0];                       
            if (~((pc_q2[11:2]==10'b0001_0000_00) && (dest_q2==PC_ADDRS))) tr2_PC_COPY <= pc_q2 + 1'b1;  //don't copy PC if interrupt vector fetch
        end      
        else if ((newthreadq==2'b10)) tr2_PC <= RPT_not_z ? tr2_PC : next_PC;   
      
    ///////////////////// thread 3 PC /////////////////
        if (tr3_ld_vector) begin
            tr3_PC <= tr3_vector;
            if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b11) && ~|pipe_flush_tr3) tr3_PC_COPY <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};
            else if ((dest_q2 == PC_ADDRS) && wrcycl) tr3_PC_COPY = resultout;
            else tr3_PC_COPY = pc_q2 + 1'b1; 
        end   
        else if (tr3_ld_vector_q3) tr3_PC <= resultout;
        else if (tr3_rewind_PC) begin
            tr3_PC <= pc_q2;
            tr3_PC_COPY <= pc_q2 + 1'b1; 
        end 
        else if (((opcode_q2==BTB_) & bitmatch) && (thread_q2==2'b11)) begin            
            tr3_PC <= pc_q2 + {dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7], dest_q2[7:0]};             
            tr3_PC_COPY <= pc_q2 + 1'b1; 
        end         
        else if ((dest_q2==PC_ADDRS) && (thread_q2==2'b11) && wrcycl) begin
            tr3_PC <= resultout[11:0];                       
            if (~((pc_q2[11:2]==10'b0001_0000_00) && (dest_q2==PC_ADDRS))) tr3_PC_COPY <= pc_q2 + 1'b1;  //don't copy PC if interrupt vector fetch
        end      
        else if ((newthreadq==2'b11)) tr3_PC <= RPT_not_z ? tr3_PC : next_PC;   

                                           
    ///////////////////// fine-grain scheduler /////////////////               
       if (wrcycl & (dest_q2==SCHED_ADDRS)) begin
          sched_cmp <= resultout;
          scheduler <= resultout;
          sched_state <= 4'b0001;
      end    
      else if (~LOCKED && ~RPT_not_z) begin      // disable if RPT or LOCKED is active

          if (|sched_cmp[7:0]) begin
              if ((scheduler[7:0]==sched_cmp[7:0]) && sched_state[0]) scheduler[7:0] <= 8'h01;
              else if (sched_state[0]) scheduler[7:0] <= scheduler[7:0] + 1'b1;
          end
          if (|sched_cmp[15:8]) begin          
              if ((scheduler[15:8]==sched_cmp[15:8]) && sched_state[1]) scheduler[15:8] <= 8'h01;
              else if (sched_state[1]) scheduler[15:8] <= scheduler[15:8] + 1'b1;
          end    
          if (|sched_cmp[23:16]) begin
              if ((scheduler[23:16]==sched_cmp[23:16]) && sched_state[2]) scheduler[23:16] <= 8'h01;
              else if (sched_state[2]) scheduler[23:16] <= scheduler[23:16] + 1'b1;
          end
          if (|sched_cmp[31:24]) begin
              if ((scheduler[31:24]==sched_cmp[31:24]) && sched_state[3]) scheduler[31:24] <= 8'h01;
              else if (sched_state[3]) scheduler[31:24] <= scheduler[31:24] + 1'b1;
          end
      end
          
      if (~LOCKED && ~RPT_not_z)  sched_state[3:0] <= {sched_state[2:0], 1'b1};      // disable if RPT or LOCKED is active
      
    ////////////////////////// FP STATUS FLAGS //////////////////////////////

         if (tr3_invalid && ~tr3_alt_inv_handl) tr3_invalid_flag <= 1'b1;                                                      
         else if (wrcycl && (thread_q2==2'b11) && (dest_q2==ST_ADDRS)) tr3_invalid_flag <= resultout[6];                       
                                                                                                                               
         if (tr2_invalid && ~tr2_alt_inv_handl) tr2_invalid_flag <= 1'b1;                                                      
         else if (wrcycl && (thread_q2==2'b10) && (dest_q2==ST_ADDRS)) tr2_invalid_flag <= resultout[6];                               
                                                                                                                                         
         if (tr1_invalid && ~tr1_alt_inv_handl) tr1_invalid_flag <= 1'b1;                                                                
         else if (wrcycl && (thread_q2==2'b01) && (dest_q2==ST_ADDRS)) tr1_invalid_flag <= resultout[6];                                 
                                                                                                                                         
         if (tr0_invalid && ~tr0_alt_inv_handl) tr0_invalid_flag <= 1'b1;                                                                
         else if (wrcycl && (thread_q2==2'b00) && (dest_q2==ST_ADDRS)) tr0_invalid_flag <= resultout[6];                                 
                                                                                                                                         
                                                                                                                                         
         if (tr3_divby0 && ~tr3_alt_div0_handl) tr3_divby0_flag <= 1'b1;                                                                 
         else if (wrcycl && (thread_q2==2'b11) && (dest_q2==ST_ADDRS)) tr3_divby0_flag <= resultout[7];                                  
                                                                                                                                          
         if (tr2_divby0 && ~tr2_alt_div0_handl) tr2_divby0_flag <= 1'b1;                                                                  
         else if (wrcycl && (thread_q2==2'b10) && (dest_q2==ST_ADDRS)) tr2_divby0_flag <= resultout[7];
         
         if (tr1_divby0 && ~tr1_alt_div0_handl) tr1_divby0_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b01) && (dest_q2==ST_ADDRS)) tr1_divby0_flag <= resultout[7];
         
         if (tr0_divby0 && ~tr0_alt_div0_handl) tr0_divby0_flag <= 1'b1;
         else if ( wrcycl && (thread_q2==2'b00) && (dest_q2==ST_ADDRS)) tr0_divby0_flag <= resultout[7];
         

         if (tr3_overflow && ~tr3_alt_ovfl_handl) tr3_overflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b11) && (dest_q2==ST_ADDRS)) tr3_overflow_flag <= resultout[8];
         
         if (tr2_overflow && ~tr2_alt_ovfl_handl) tr2_overflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b10) && (dest_q2==ST_ADDRS)) tr2_overflow_flag <= resultout[8];
         
         if (tr1_overflow && ~tr1_alt_ovfl_handl) tr1_overflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b01) && (dest_q2==ST_ADDRS)) tr1_overflow_flag <= resultout[8];
         
         if (tr0_overflow && ~tr0_alt_ovfl_handl) tr0_overflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b00) && (dest_q2==ST_ADDRS)) tr0_overflow_flag <= resultout[8];
         
         
         if (tr3_underflow && ~tr3_alt_unfl_handl) tr3_underflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b11) && (dest_q2==ST_ADDRS)) tr3_underflow_flag <= resultout[9];
         
         if (tr2_underflow && ~tr2_alt_unfl_handl) tr2_underflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b10) && (dest_q2==ST_ADDRS)) tr2_underflow_flag <= resultout[9];                               
                                                                                                                                         
         if (tr1_underflow && ~tr1_alt_unfl_handl) tr1_underflow_flag <= 1'b1;                                                           
         else if (wrcycl && (thread_q2==2'b01) && (dest_q2==ST_ADDRS)) tr1_underflow_flag <= resultout[9];                               
                                                                                                                                         
         if (tr0_underflow && ~tr0_alt_unfl_handl) tr0_underflow_flag <= 1'b1;
         else if (wrcycl && (thread_q2==2'b00) && (dest_q2==ST_ADDRS)) tr0_underflow_flag <= resultout[9];
         
                                                                                                                          
         if (wrcycl && (thread_q2==2'b11) && (dest_q2==ST_ADDRS)) tr3_inexact_flag <= resultout[10];                     
                                                                                                                         
         if (wrcycl && (thread_q2==2'b10) && (dest_q2==ST_ADDRS)) tr2_inexact_flag <= resultout[10];                     
                                                                                                                         
         if (wrcycl && (thread_q2==2'b01) && (dest_q2==ST_ADDRS)) tr1_inexact_flag <= resultout[10];
         
         if (wrcycl && (thread_q2==2'b00) && (dest_q2==ST_ADDRS)) tr0_inexact_flag <= resultout[10];
 

         if ((dest_q2==ST_ADDRS) && wrcycl) begin
            case (thread_q2)  
                2'b00 : {tr0_IRQ_IE, tr0_alt_del_nxact, tr0_alt_del_unfl, tr0_alt_del_ovfl, tr0_alt_del_div0, tr0_alt_del_inv, tr0_alt_nxact_handl, tr0_alt_unfl_handl, tr0_alt_ovfl_handl, tr0_alt_div0_handl, tr0_alt_inv_handl, tr0_done, tr0_locked, tr0_V, tr0_N, tr0_C, tr0_Z} <= {resultout[21:11], resultout[5:0]}; 
                2'b01 : {tr1_IRQ_IE, tr1_alt_del_nxact, tr1_alt_del_unfl, tr1_alt_del_ovfl, tr1_alt_del_div0, tr1_alt_del_inv, tr1_alt_nxact_handl, tr1_alt_unfl_handl, tr1_alt_ovfl_handl, tr1_alt_div0_handl, tr1_alt_inv_handl, tr1_done, tr1_locked, tr1_V, tr1_N, tr1_C, tr1_Z} <= {resultout[21:11], resultout[5:0]}; 
                2'b10 : {tr2_IRQ_IE, tr2_alt_del_nxact, tr2_alt_del_unfl, tr2_alt_del_ovfl, tr2_alt_del_div0, tr2_alt_del_inv, tr2_alt_nxact_handl, tr2_alt_unfl_handl, tr2_alt_ovfl_handl, tr2_alt_div0_handl, tr2_alt_inv_handl, tr2_done, tr2_locked, tr2_V, tr2_N, tr2_C, tr2_Z} <= {resultout[21:11], resultout[5:0]}; 
                2'b11 : {tr3_IRQ_IE, tr3_alt_del_nxact, tr3_alt_del_unfl, tr3_alt_del_ovfl, tr3_alt_del_div0, tr3_alt_del_inv, tr3_alt_nxact_handl, tr3_alt_unfl_handl, tr3_alt_ovfl_handl, tr3_alt_div0_handl, tr3_alt_inv_handl, tr3_done, tr3_locked, tr3_V, tr3_N, tr3_C, tr3_Z} <= {resultout[21:11], resultout[5:0]}; 
            endcase
         end
         else if (wrcycl)
            case (thread_q2)
                2'b00 : {tr0_V, tr0_N, tr0_C, tr0_Z} <= {V_q2, N_q2, C_q2, Z_q2};
                2'b01 : {tr1_V, tr1_N, tr1_C, tr1_Z} <= {V_q2, N_q2, C_q2, Z_q2};
                2'b10 : {tr2_V, tr2_N, tr2_C, tr2_Z} <= {V_q2, N_q2, C_q2, Z_q2};
                2'b11 : {tr3_V, tr3_N, tr3_C, tr3_Z} <= {V_q2, N_q2, C_q2, Z_q2};
            endcase
           
        if ((dest_q2==CREG_ADDRS) && wrcycl)
            case(thread_q2)
                2'b00 : tr0_C_reg <= resultout;
                2'b01 : tr1_C_reg <= resultout;
                2'b10 : tr2_C_reg <= resultout;
                2'b11 : tr3_C_reg <= resultout;
            endcase    
         
        if ((dest_q2==TIMER_ADDRS) && wrcycl) 
            case(thread_q2)
                2'b00 : begin
                           tr0_timer <= 20'h00000;
                           tr0_timercmpr <= resultout[19:0];
                        end   
                2'b01 : begin
                           tr1_timer <= 20'h00000;
                           tr1_timercmpr <= resultout[19:0];
                        end   
                2'b10 : begin
                           tr2_timer <= 20'h00000;
                           tr2_timercmpr <= resultout[19:0];
                        end   
                2'b11 : begin
                           tr3_timer <= 20'h00000;
                           tr3_timercmpr <= resultout[19:0];
                        end 
            endcase
        else begin
            if (~tr0_done && ~(tr0_timer==tr0_timercmpr)) tr0_timer <= tr0_timer + 1'b1;                   
            if (~tr1_done && ~(tr1_timer==tr1_timercmpr)) tr1_timer <= tr1_timer + 1'b1;                   
            if (~tr2_done && ~(tr2_timer==tr2_timercmpr)) tr2_timer <= tr2_timer + 1'b1;                   
            if (~tr3_done && ~(tr3_timer==tr3_timercmpr)) tr3_timer <= tr3_timer + 1'b1;                   
        end
                        
        STATE <= {1'b1, STATE[2:1]};    //rotate right 1 into msb  (shift right)
     
        if (LD_newthread) newthreadq <= newthread;
        round_mode_q1 <= round_mode;
        thread_q1   <= newthreadq ; 
        pc_q1       <= PC         ; 
        constn_q1   <= constn     ;                 
        opcode_q1   <= opcode     ; 
        srcA_q1     <= srcA       ; 
        srcB_q1     <= srcB       ; 
        OPdest_q1   <= OPdest     ;
        OPsrcA_q1   <= OPsrcA     ;
        OPsrcB_q1   <= OPsrcB     ;
        
        fp_ready_q2 <= fp_ready_q1;
        fp_sel_q2   <= fp_sel_q1  ;
        thread_q2   <= thread_q1  ; 
        pc_q2       <= pc_q1      ;  
        opcode_q2   <= opcode_q1  ; 
        srcA_q2     <= srcA_q1    ; 
        srcB_q2     <= srcB_q1    ; 
        OPdest_q2   <= OPdest_q1  ;
        OPsrcA_q2   <= OPsrcA_q1  ;
       
        casex (opcode_q1)      //read data stored temporarily in wrsrcAdata and wrsrcBdata
        
           RCP_,
           SIN_,
           COS_,
           TAN_,
           COT_, 
           MOV_ :  case(constn_q1)
                     2'b00 : begin    // both srcA and srcB are either direct or indirect
                                wrsrcAdata <= rdSrcAdata;             
                                wrsrcBdata <= rdSrcBdata; 
                             end
                     2'b01 : begin   //srcA is direct or indirect and srcB is 8-bit immediate
                                wrsrcAdata <= rdSrcAdata;             
                                wrsrcBdata <= {24'h000000, OPsrcB_q1};
                             end
                     2'b10 : begin  //srcA is table-read and srcB is direct or indirect 
                                wrsrcAdata <= rdSrcAdata;             
                                wrsrcBdata <= rdSrcBdata; 
                             end
                     2'b11 : begin //16-bit immediate       
                                wrsrcAdata <= {16'h0000, OPsrcA_q1, OPsrcB_q1};
                                wrsrcBdata <= rdSrcBdata; 
                             end
                   endcase           

            OR_,    
           XOR_,    
           AND_,    
           ADD_,
          ADDC_,
           SUB_,
          SUBB_,
           MUL_,
          SHFT_,
           BTB_  : begin    
                     if (constn_q1[0]) begin    //immediate
                         wrsrcBdata <= {24'h000000, OPsrcB_q1};
                         wrsrcAdata <= rdSrcAdata;
                     end
                     else begin
                         wrsrcBdata <= rdSrcBdata;
                         wrsrcAdata <= rdSrcAdata;
                     end
                   end          
        endcase
        
        if (~RPT_not_z && &constn && (OPdest[7:2]==6'b011100))      //immediate loads of ARn occur during instruction fetch (state0)
            casex (newthreadq)
                2'b00 : if (~(discont && (thread_q2==2'b00))) 
                        casex (OPdest)   //only [12:0] written during immediate write to ARn
                          8'h70 : tr0_AR0[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; //direct write to ARn during newthreadq has priority over any update
                          8'h71 : tr0_AR1[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                          8'h72 : tr0_AR2[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                          8'h73 : tr0_AR3[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]};
                        endcase
                2'b01 : if (~(discont && (thread_q2==2'b01)))
                        casex (OPdest)  //only [12:0] written during immediate write to ARn
                           8'h70 : tr1_AR0[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; //direct write to ARn during newthreadq has priority over any update
                           8'h71 : tr1_AR1[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                           8'h72 : tr1_AR2[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                           8'h73 : tr1_AR3[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]};
                        endcase
                2'b10 : if (~(discont && (thread_q2==2'b10)))
                        casex (OPdest)   //only [12:0] written during immediate write to ARn
                           8'h70 : tr2_AR0[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; //direct write to ARn during newthreadq has priority over any update
                           8'h71 : tr2_AR1[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                           8'h72 : tr2_AR2[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                           8'h73 : tr2_AR3[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]};
                        endcase
                2'b11 : if (~(discont && (thread_q2==2'b11)))
                        casex (OPdest)  //only [12:0] written during immediate write to ARn
                           8'h70 : tr3_AR0[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; //direct write to ARn during newthreadq has priority over any update
                           8'h71 : tr3_AR1[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                           8'h72 : tr3_AR2[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]}; 
                           8'h73 : tr3_AR3[13:0] <= {OPsrcA[5:0], OPsrcB[7:0]};
                        endcase
            endcase
        else if (wrcycl && ~RPT_not_z)
            casex (thread_q2)  //direct or table-read loads of ARn occur during usual write (state2) 
                2'b00 : casex (OPdest_q2)
                           8'h70 : tr0_AR0 <= {(|resultout[31:24] ? resultout[31:24] : tr0_AR0[31:24]), (|resultout[23:16] ? resultout[23:16] : tr0_AR0[23:16]), 2'b00, resultout[13:0]}; //direct write to ARn during q2 has priority over any update
                           8'h71 : tr0_AR1 <= {(|resultout[31:24] ? resultout[31:24] : tr0_AR1[31:24]), (|resultout[23:16] ? resultout[23:16] : tr0_AR1[23:16]), 2'b00, resultout[13:0]}; 
                           8'h72 : tr0_AR2 <= {(|resultout[31:24] ? resultout[31:24] : tr0_AR2[31:24]), (|resultout[23:16] ? resultout[23:16] : tr0_AR2[23:16]), 2'b00, resultout[13:0]}; 
                           8'h73 : tr0_AR3 <= {(|resultout[31:24] ? resultout[31:24] : tr0_AR3[31:24]), (|resultout[23:16] ? resultout[23:16] : tr0_AR3[23:16]), 2'b00, resultout[13:0]};
                        endcase
                2'b01 : casex (OPdest_q2)
                           8'h70 : tr1_AR0 <= {(|resultout[31:24] ? resultout[31:24] : tr1_AR0[31:24]), (|resultout[23:16] ? resultout[23:16] : tr1_AR0[23:16]), 2'b00, resultout[13:0]}; //direct write to ARn during q2 has priority over any update
                           8'h71 : tr1_AR1 <= {(|resultout[31:24] ? resultout[31:24] : tr1_AR1[31:24]), (|resultout[23:16] ? resultout[23:16] : tr1_AR1[23:16]), 2'b00, resultout[13:0]}; 
                           8'h72 : tr1_AR2 <= {(|resultout[31:24] ? resultout[31:24] : tr1_AR2[31:24]), (|resultout[23:16] ? resultout[23:16] : tr1_AR2[23:16]), 2'b00, resultout[13:0]}; 
                           8'h73 : tr1_AR3 <= {(|resultout[31:24] ? resultout[31:24] : tr1_AR3[31:24]), (|resultout[23:16] ? resultout[23:16] : tr1_AR3[23:16]), 2'b00, resultout[13:0]};
                        endcase
                2'b10 : casex (OPdest_q2)
                           8'h70 : tr2_AR0 <= {(|resultout[31:24] ? resultout[31:24] : tr2_AR0[31:24]), (|resultout[23:16] ? resultout[23:16] : tr2_AR0[23:16]), 2'b00, resultout[13:0]}; //direct write to ARn during q2 has priority over any update
                           8'h71 : tr2_AR1 <= {(|resultout[31:24] ? resultout[31:24] : tr2_AR1[31:24]), (|resultout[23:16] ? resultout[23:16] : tr2_AR1[23:16]), 2'b00, resultout[13:0]}; 
                           8'h72 : tr2_AR2 <= {(|resultout[31:24] ? resultout[31:24] : tr2_AR2[31:24]), (|resultout[23:16] ? resultout[23:16] : tr2_AR2[23:16]), 2'b00, resultout[13:0]}; 
                           8'h73 : tr2_AR3 <= {(|resultout[31:24] ? resultout[31:24] : tr2_AR3[31:24]), (|resultout[23:16] ? resultout[23:16] : tr2_AR3[23:16]), 2'b00, resultout[13:0]};
                        endcase
                2'b11 : casex (OPdest_q2)
                           8'h70 : tr3_AR0 <= {(|resultout[31:24] ? resultout[31:24] : tr3_AR0[31:24]), (|resultout[23:16] ? resultout[23:16] : tr3_AR0[23:16]), 2'b00, resultout[13:0]}; //direct write to ARn during q2 has priority over any update
                           8'h71 : tr3_AR1 <= {(|resultout[31:24] ? resultout[31:24] : tr3_AR1[31:24]), (|resultout[23:16] ? resultout[23:16] : tr3_AR1[23:16]), 2'b00, resultout[13:0]}; 
                           8'h72 : tr3_AR2 <= {(|resultout[31:24] ? resultout[31:24] : tr3_AR2[31:24]), (|resultout[23:16] ? resultout[23:16] : tr3_AR2[23:16]), 2'b00, resultout[13:0]}; 
                           8'h73 : tr3_AR3 <= {(|resultout[31:24] ? resultout[31:24] : tr3_AR3[31:24]), (|resultout[23:16] ? resultout[23:16] : tr3_AR3[23:16]), 2'b00, resultout[13:0]};
                        endcase
            endcase   

        if ( ~constn[1])      //ARn auto-post-increment/decrement of indirect srcA address ARn occurs during instruction fetch (state0)           
        casex (newthreadq)
            2'b00 : if (~((thread_q2==2'b00) && discont))
                        casex (OPsrcA)
                            8'h78 : tr0_AR0[13:0] <= tr0_AR0[13:0] + tr0_AR0[23:16];
                            8'h7C : tr0_AR0[13:0] <= tr0_AR0[13:0] - tr0_AR0[31:24];
                            8'h79 : tr0_AR1[13:0] <= tr0_AR1[13:0] + tr0_AR1[23:16];
                            8'h7D : tr0_AR1[13:0] <= tr0_AR1[13:0] - tr0_AR1[31:24];
                            8'h7A : tr0_AR2[13:0] <= tr0_AR2[13:0] + tr0_AR2[23:16];
                            8'h7E : tr0_AR2[13:0] <= tr0_AR2[13:0] - tr0_AR2[31:24];
                            8'h7B : tr0_AR3[13:0] <= tr0_AR3[13:0] + tr0_AR3[23:16];
                            8'h7F : tr0_AR3[13:0] <= tr0_AR3[13:0] - tr0_AR3[31:24];
                        endcase 
            2'b01 : if (~((thread_q2==2'b01) && discont))
                        casex (OPsrcA)
                            8'h78 : tr1_AR0[13:0] <= tr1_AR0[13:0] + tr1_AR0[23:16];
                            8'h7C : tr1_AR0[13:0] <= tr1_AR0[13:0] - tr1_AR0[31:24];
                            8'h79 : tr1_AR1[13:0] <= tr1_AR1[13:0] + tr1_AR1[23:16];
                            8'h7D : tr1_AR1[13:0] <= tr1_AR1[13:0] - tr1_AR1[31:24];
                            8'h7A : tr1_AR2[13:0] <= tr1_AR2[13:0] + tr1_AR2[23:16];
                            8'h7E : tr1_AR2[13:0] <= tr1_AR2[13:0] - tr1_AR2[31:24];
                            8'h7B : tr1_AR3[13:0] <= tr1_AR3[13:0] + tr1_AR3[23:16];
                            8'h7F : tr1_AR3[13:0] <= tr1_AR3[13:0] - tr1_AR3[31:24];
                        endcase    
            2'b10 : if (~((thread_q2==2'b10) && discont))
                        casex (OPsrcA)
                            8'h78 : tr2_AR0[13:0] <= tr2_AR0[13:0] + tr2_AR0[23:16];
                            8'h7C : tr2_AR0[13:0] <= tr2_AR0[13:0] - tr2_AR0[31:24];
                            8'h79 : tr2_AR1[13:0] <= tr2_AR1[13:0] + tr2_AR1[23:16];
                            8'h7D : tr2_AR1[13:0] <= tr2_AR1[13:0] - tr2_AR1[31:24];
                            8'h7A : tr2_AR2[13:0] <= tr2_AR2[13:0] + tr2_AR2[23:16];
                            8'h7E : tr2_AR2[13:0] <= tr2_AR2[13:0] - tr2_AR2[31:24];
                            8'h7B : tr2_AR3[13:0] <= tr2_AR3[13:0] + tr2_AR3[23:16];
                            8'h7F : tr2_AR3[13:0] <= tr2_AR3[13:0] - tr2_AR3[31:24];
                        endcase    
            2'b11 : if (~((thread_q2==2'b11) && discont))
                        casex (OPsrcA)
                            8'h78 : tr3_AR0[13:0] <= tr3_AR0[13:0] + tr3_AR0[23:16];
                            8'h7C : tr3_AR0[13:0] <= tr3_AR0[13:0] - tr3_AR0[31:24];
                            8'h79 : tr3_AR1[13:0] <= tr3_AR1[13:0] + tr3_AR1[23:16];
                            8'h7D : tr3_AR1[13:0] <= tr3_AR1[13:0] - tr3_AR1[31:24];
                            8'h7A : tr3_AR2[13:0] <= tr3_AR2[13:0] + tr3_AR2[23:16];
                            8'h7E : tr3_AR2[13:0] <= tr3_AR2[13:0] - tr3_AR2[31:24];
                            8'h7B : tr3_AR3[13:0] <= tr3_AR3[13:0] + tr3_AR3[23:16];
                            8'h7F : tr3_AR3[13:0] <= tr3_AR3[13:0] - tr3_AR3[31:24];
                        endcase    
        endcase 
            
        if (~constn[0])     //ARn auto-post-increment/decrement of indirect srcB address ARn occurs during instruction fetch (state0)
        casex (newthreadq)
            2'b00 : if (~((thread_q2==2'b00) && discont))
                        casex (OPsrcB)
                           8'h78 : tr0_AR0[13:0] <= tr0_AR0[13:0] + tr0_AR0[23:16];
                           8'h7C : tr0_AR0[13:0] <= tr0_AR0[13:0] - tr0_AR0[31:24];
                           8'h79 : tr0_AR1[13:0] <= tr0_AR1[13:0] + tr0_AR1[23:16];
                           8'h7D : tr0_AR1[13:0] <= tr0_AR1[13:0] - tr0_AR1[31:24];
                           8'h7A : tr0_AR2[13:0] <= tr0_AR2[13:0] + tr0_AR2[23:16];
                           8'h7E : tr0_AR2[13:0] <= tr0_AR2[13:0] - tr0_AR2[31:24];
                           8'h7B : tr0_AR3[13:0] <= tr0_AR3[13:0] + tr0_AR3[23:16];
                           8'h7F : tr0_AR3[13:0] <= tr0_AR3[13:0] - tr0_AR3[31:24];
                        endcase 
            2'b01 : if (~((thread_q2==2'b01) && discont))
                        casex (OPsrcB)
                           8'h78 : tr1_AR0[13:0] <= tr1_AR0[13:0] + tr1_AR0[23:16];
                           8'h7C : tr1_AR0[13:0] <= tr1_AR0[13:0] - tr1_AR0[31:24];
                           8'h79 : tr1_AR1[13:0] <= tr1_AR1[13:0] + tr1_AR1[23:16];
                           8'h7D : tr1_AR1[13:0] <= tr1_AR1[13:0] - tr1_AR1[31:24];
                           8'h7A : tr1_AR2[13:0] <= tr1_AR2[13:0] + tr1_AR2[23:16];
                           8'h7E : tr1_AR2[13:0] <= tr1_AR2[13:0] - tr1_AR2[31:24];
                           8'h7B : tr1_AR3[13:0] <= tr1_AR3[13:0] + tr1_AR3[23:16];
                           8'h7F : tr1_AR3[13:0] <= tr1_AR3[13:0] - tr1_AR3[31:24];
                        endcase    
            2'b10 : if (~((thread_q2==2'b10) && discont))
                        casex (OPsrcB)
                           8'h78 : tr2_AR0[13:0] <= tr2_AR0[13:0] + tr2_AR0[23:16];
                           8'h7C : tr2_AR0[13:0] <= tr2_AR0[13:0] - tr2_AR0[31:24];
                           8'h79 : tr2_AR1[13:0] <= tr2_AR1[13:0] + tr2_AR1[23:16];
                           8'h7D : tr2_AR1[13:0] <= tr2_AR1[13:0] - tr2_AR1[31:24];
                           8'h7A : tr2_AR2[13:0] <= tr2_AR2[13:0] + tr2_AR2[23:16];
                           8'h7E : tr2_AR2[13:0] <= tr2_AR2[13:0] - tr2_AR2[31:24];
                           8'h7B : tr2_AR3[13:0] <= tr2_AR3[13:0] + tr2_AR3[23:16];
                           8'h7F : tr2_AR3[13:0] <= tr2_AR3[13:0] - tr2_AR3[31:24];
                        endcase    
            2'b11 : if (~((thread_q2==2'b11) && discont))
                        casex (OPsrcB)
                           8'h78 : tr3_AR0[13:0] <= tr3_AR0[13:0] + tr3_AR0[23:16];
                           8'h7C : tr3_AR0[13:0] <= tr3_AR0[13:0] - tr3_AR0[31:24];
                           8'h79 : tr3_AR1[13:0] <= tr3_AR1[13:0] + tr3_AR1[23:16];
                           8'h7D : tr3_AR1[13:0] <= tr3_AR1[13:0] - tr3_AR1[31:24];
                           8'h7A : tr3_AR2[13:0] <= tr3_AR2[13:0] + tr3_AR2[23:16];
                           8'h7E : tr3_AR2[13:0] <= tr3_AR2[13:0] - tr3_AR2[31:24];
                           8'h7B : tr3_AR3[13:0] <= tr3_AR3[13:0] + tr3_AR3[23:16];
                           8'h7F : tr3_AR3[13:0] <= tr3_AR3[13:0] - tr3_AR3[31:24];
                        endcase    
        endcase            
          
        if (wrcycl) 
        casex (thread_q2)        //ARn auto-post-increment/decrement of indirect destination address ARn occurs during usual write (state2)
           2'b00 : casex (OPdest_q2)
                      8'h78 : tr0_AR0[13:0] <= tr0_AR0[13:0] + tr0_AR0[23:16];
                      8'h7C : tr0_AR0[13:0] <= tr0_AR0[13:0] - tr0_AR0[31:24];
                      8'h79 : tr0_AR1[13:0] <= tr0_AR1[13:0] + tr0_AR1[23:16];
                      8'h7D : tr0_AR1[13:0] <= tr0_AR1[13:0] - tr0_AR1[31:24];
                      8'h7A : tr0_AR2[13:0] <= tr0_AR2[13:0] + tr0_AR2[23:16];
                      8'h7E : tr0_AR2[13:0] <= tr0_AR2[13:0] - tr0_AR2[31:24];
                      8'h7B : tr0_AR3[13:0] <= tr0_AR3[13:0] + tr0_AR3[23:16];
                      8'h7F : tr0_AR3[13:0] <= tr0_AR3[13:0] - tr0_AR3[31:24];
                   endcase
           2'b01 : casex (OPdest_q2)
                      8'h78 : tr1_AR0[13:0] <= tr1_AR0[13:0] + tr1_AR0[23:16];
                      8'h7C : tr1_AR0[13:0] <= tr1_AR0[13:0] - tr1_AR0[31:24];
                      8'h79 : tr1_AR1[13:0] <= tr1_AR1[13:0] + tr1_AR1[23:16];
                      8'h7D : tr1_AR1[13:0] <= tr1_AR1[13:0] - tr1_AR1[31:24];
                      8'h7A : tr1_AR2[13:0] <= tr1_AR2[13:0] + tr1_AR2[23:16];
                      8'h7E : tr1_AR2[13:0] <= tr1_AR2[13:0] - tr1_AR2[31:24];
                      8'h7B : tr1_AR3[13:0] <= tr1_AR3[13:0] + tr1_AR3[23:16];
                      8'h7F : tr1_AR3[13:0] <= tr1_AR3[13:0] - tr1_AR3[31:24];
                       endcase
           2'b10 : casex (OPdest_q2)
                      8'h78 : tr2_AR0[13:0] <= tr2_AR0[13:0] + tr2_AR0[23:16];
                      8'h7C : tr2_AR0[13:0] <= tr2_AR0[13:0] - tr2_AR0[31:24];
                      8'h79 : tr2_AR1[13:0] <= tr2_AR1[13:0] + tr2_AR1[23:16];
                      8'h7D : tr2_AR1[13:0] <= tr2_AR1[13:0] - tr2_AR1[31:24];
                      8'h7A : tr2_AR2[13:0] <= tr2_AR2[13:0] + tr2_AR2[23:16];
                      8'h7E : tr2_AR2[13:0] <= tr2_AR2[13:0] - tr2_AR2[31:24];
                      8'h7B : tr2_AR3[13:0] <= tr2_AR3[13:0] + tr2_AR3[23:16];
                      8'h7F : tr2_AR3[13:0] <= tr2_AR3[13:0] - tr2_AR3[31:24];
                       endcase
           2'b11 : casex (OPdest_q2)
                      8'h78 : tr3_AR0[13:0] <= tr3_AR0[13:0] + tr3_AR0[23:16];
                      8'h7C : tr3_AR0[13:0] <= tr3_AR0[13:0] - tr3_AR0[31:24];
                      8'h79 : tr3_AR1[13:0] <= tr3_AR1[13:0] + tr3_AR1[23:16];
                      8'h7D : tr3_AR1[13:0] <= tr3_AR1[13:0] - tr3_AR1[31:24];
                      8'h7A : tr3_AR2[13:0] <= tr3_AR2[13:0] + tr3_AR2[23:16];
                      8'h7E : tr3_AR2[13:0] <= tr3_AR2[13:0] - tr3_AR2[31:24];
                      8'h7B : tr3_AR3[13:0] <= tr3_AR3[13:0] + tr3_AR3[23:16];
                      8'h7F : tr3_AR3[13:0] <= tr3_AR3[13:0] - tr3_AR3[31:24];
                   endcase
        endcase                        
    end           
end
                                                      
endmodule