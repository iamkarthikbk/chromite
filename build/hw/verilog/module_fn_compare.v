//
// Generated by Bluespec Compiler, version 2021.07-3-g8227dc97 (build 8227dc97)
//
// On Sat Oct  2 15:35:16 +0530 2021
//
//
// Ports:
// Name                         I/O  size props
// fn_compare                     O     1
// fn_compare_op1                 I    64
// fn_compare_op2                 I    64
// fn_compare_fn                  I     4
// fn_compare_op1_xor_op2         I    64 unused
//
// Combinational paths from inputs to outputs:
//   (fn_compare_op1, fn_compare_op2, fn_compare_fn) -> fn_compare
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

module module_fn_compare(fn_compare_op1,
			 fn_compare_op2,
			 fn_compare_fn,
			 fn_compare_op1_xor_op2,
			 fn_compare);
  // value method fn_compare
  input  [63 : 0] fn_compare_op1;
  input  [63 : 0] fn_compare_op2;
  input  [3 : 0] fn_compare_fn;
  input  [63 : 0] fn_compare_op1_xor_op2;
  output fn_compare;

  // signals for module outputs
  wire fn_compare;

  // remaining internal signals
  wire sign__h21;

  // value method fn_compare
  assign fn_compare =
	     ({ sign__h21 & fn_compare_op1[63], fn_compare_op1 } ^
	      65'h10000000000000000) <
	     ({ sign__h21 & fn_compare_op2[63], fn_compare_op2 } ^
	      65'h10000000000000000) ;

  // remaining internal signals
  assign sign__h21 = ~fn_compare_fn[1] ;
endmodule  // module_fn_compare
