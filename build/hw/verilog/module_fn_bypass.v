//
// Generated by Bluespec Compiler, version 2021.07-3-g8227dc97 (build 8227dc97)
//
// On Sat Oct  2 15:35:15 +0530 2021
//
//
// Ports:
// Name                         I/O  size props
// fn_bypass                      O    65
// fn_bypass_req                  I    11
// fn_bypass_fwd                  I   225
//
// Combinational paths from inputs to outputs:
//   (fn_bypass_req, fn_bypass_fwd) -> fn_bypass
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

module module_fn_bypass(fn_bypass_req,
			fn_bypass_fwd,
			fn_bypass);
  // value method fn_bypass
  input  [10 : 0] fn_bypass_req;
  input  [224 : 0] fn_bypass_fwd;
  output [64 : 0] fn_bypass;

  // signals for module outputs
  wire [64 : 0] fn_bypass;

  // remaining internal signals
  wire [63 : 0] x__h432;
  wire [1 : 0] IF_fn_bypass_fwd_BIT_70_4_AND_fn_bypass_fwd_BI_ETC___d24,
	       x__h30;

  // value method fn_bypass
  assign fn_bypass = { x__h30 != 2'd0 || !fn_bypass_req[1], x__h432 } ;

  // remaining internal signals
  assign IF_fn_bypass_fwd_BIT_70_4_AND_fn_bypass_fwd_BI_ETC___d24 =
	     (fn_bypass_fwd[70] &&
	      fn_bypass_fwd[69:65] == fn_bypass_req[6:2] &&
	      fn_bypass_fwd[0] == fn_bypass_req[0] &&
	      fn_bypass_fwd[74:71] == fn_bypass_req[10:7]) ?
	       2'd1 :
	       2'd0 ;
  assign x__h30 =
	     { fn_bypass_fwd[145] &&
	       fn_bypass_fwd[144:140] == fn_bypass_req[6:2] &&
	       fn_bypass_fwd[75] == fn_bypass_req[0] &&
	       fn_bypass_fwd[149:146] == fn_bypass_req[10:7],
	       IF_fn_bypass_fwd_BIT_70_4_AND_fn_bypass_fwd_BI_ETC___d24[0] } ;
  assign x__h432 =
	     IF_fn_bypass_fwd_BIT_70_4_AND_fn_bypass_fwd_BI_ETC___d24[0] ?
	       fn_bypass_fwd[64:1] :
	       ((x__h30 == 2'b10) ?
		  fn_bypass_fwd[139:76] :
		  fn_bypass_fwd[214:151]) ;
endmodule  // module_fn_bypass
