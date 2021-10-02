//
// Generated by Bluespec Compiler, version 2021.07-3-g8227dc97 (build 8227dc97)
//
// On Sat Oct  2 15:35:17 +0530 2021
//
//
// Ports:
// Name                         I/O  size props
// fn_decode_rs2                  O     5
// fn_decode_rs2_inst             I    32
// fn_decode_rs2_csrs             I   143 unused
//
// Combinational paths from inputs to outputs:
//   fn_decode_rs2_inst -> fn_decode_rs2
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

module module_fn_decode_rs2(fn_decode_rs2_inst,
			    fn_decode_rs2_csrs,
			    fn_decode_rs2);
  // value method fn_decode_rs2
  input  [31 : 0] fn_decode_rs2_inst;
  input  [142 : 0] fn_decode_rs2_csrs;
  output [4 : 0] fn_decode_rs2;

  // signals for module outputs
  wire [4 : 0] fn_decode_rs2;

  // value method fn_decode_rs2
  assign fn_decode_rs2 =
	     (fn_decode_rs2_inst[6:2] == 5'b11011 ||
	      fn_decode_rs2_inst[6:2] == 5'b11001 ||
	      fn_decode_rs2_inst[6:2] == 5'b01101 ||
	      fn_decode_rs2_inst[6:2] == 5'b00101 ||
	      fn_decode_rs2_inst[6:4] == 3'b0) ?
	       5'd0 :
	       ((fn_decode_rs2_inst[6:2] == 5'b11100) ?
		  ((fn_decode_rs2_inst[14:12] != 3'd0 ||
		    fn_decode_rs2_inst[31:25] != 7'b0001001) ?
		     5'd0 :
		     fn_decode_rs2_inst[24:20]) :
		  ((fn_decode_rs2_inst[6:4] == 3'b001) ?
		     5'd0 :
		     fn_decode_rs2_inst[24:20])) ;
endmodule  // module_fn_decode_rs2

