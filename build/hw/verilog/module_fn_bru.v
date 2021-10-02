//
// Generated by Bluespec Compiler, version 2021.07-3-g8227dc97 (build 8227dc97)
//
// On Sat Oct  2 15:35:16 +0530 2021
//
//
// Ports:
// Name                         I/O  size props
// fn_bru                         O     1
// fn_bru_op1                     I    64
// fn_bru_op2                     I    64
// fn_bru_fn                      I     4
//
// Combinational paths from inputs to outputs:
//   (fn_bru_op1, fn_bru_op2, fn_bru_fn) -> fn_bru
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module module_fn_bru(fn_bru_op1,
		     fn_bru_op2,
		     fn_bru_fn,
		     fn_bru);
  // value method fn_bru
  input  [63 : 0] fn_bru_op1;
  input  [63 : 0] fn_bru_op2;
  input  [3 : 0] fn_bru_fn;
  output fn_bru;

  // signals for module outputs
  reg fn_bru;

  // remaining internal signals
  wire [63 : 0] op1_xor_op2__h21;
  wire INV_fn_bru_fn_BIT_1_0_1_AND_fn_bru_op1_BIT_63__ETC___d18,
       adder_z_flag__h23,
       sign__h22;

  // value method fn_bru
  always@(fn_bru_fn or
	  INV_fn_bru_fn_BIT_1_0_1_AND_fn_bru_op1_BIT_63__ETC___d18 or
	  adder_z_flag__h23 or op1_xor_op2__h21)
  begin
    case (fn_bru_fn)
      4'd2: fn_bru = adder_z_flag__h23;
      4'd3: fn_bru = op1_xor_op2__h21 != 64'd0;
      4'd12, 4'd14:
	  fn_bru = INV_fn_bru_fn_BIT_1_0_1_AND_fn_bru_op1_BIT_63__ETC___d18;
      default: fn_bru =
		   !INV_fn_bru_fn_BIT_1_0_1_AND_fn_bru_op1_BIT_63__ETC___d18;
    endcase
  end

  // remaining internal signals
  assign INV_fn_bru_fn_BIT_1_0_1_AND_fn_bru_op1_BIT_63__ETC___d18 =
	     ({ sign__h22 & fn_bru_op1[63], fn_bru_op1 } ^
	      65'h10000000000000000) <
	     ({ sign__h22 & fn_bru_op2[63], fn_bru_op2 } ^
	      65'h10000000000000000) ;
  assign adder_z_flag__h23 = ~(op1_xor_op2__h21 != 64'd0) ;
  assign op1_xor_op2__h21 = fn_bru_op1 ^ fn_bru_op2 ;
  assign sign__h22 = ~fn_bru_fn[1] ;
endmodule  // module_fn_bru

