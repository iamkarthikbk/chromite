//
// Generated by Bluespec Compiler, version 2021.07-3-g8227dc97 (build 8227dc97)
//
// On Sat Oct  2 15:35:51 +0530 2021
//
//
// Ports:
// Name                         I/O  size props
// fn_decompress                  O    32
// fn_decompress_inst             I    16
//
// Combinational paths from inputs to outputs:
//   fn_decompress_inst -> fn_decompress
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

module module_fn_decompress(fn_decompress_inst,
			    fn_decompress);
  // value method fn_decompress
  input  [15 : 0] fn_decompress_inst;
  output [31 : 0] fn_decompress;

  // signals for module outputs
  wire [31 : 0] fn_decompress;

  // remaining internal signals
  wire [31 : 0] IF_fn_decompress_inst_BITS_15_TO_11_11_EQ_0b10_ETC___d320,
		IF_fn_decompress_inst_BITS_15_TO_11_11_EQ_0b10_ETC___d323,
		IF_fn_decompress_inst_BITS_15_TO_12_EQ_0b1000__ETC___d322,
		IF_fn_decompress_inst_BITS_15_TO_12_EQ_0b1001__ETC___d319,
		IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b100_8_ETC___d336,
		IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b10_2__ETC___d325,
		IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b110_8_ETC___d318,
		IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b111_7_ETC___d344,
		IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b11_2__ETC___d346,
		IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b1_2_A_ETC___d342,
		IF_fn_decompress_inst_BITS_15_TO_7_3_EQ_0b1110_ETC___d340;
  wire [11 : 0] SEXT_fn_decompress_inst_BIT_12_0_CONCAT_fn_dec_ETC___d67;
  wire [9 : 0] x__h1408, x__h4254;
  wire [8 : 0] x__h12235;
  wire [7 : 0] x__h12096, x__h1733;
  wire [6 : 0] x__h1569;
  wire [5 : 0] fn_decompress_inst_BIT_12_CONCAT_fn_decompress_ETC__q1;
  wire [3 : 0] x__h14618;
  wire [2 : 0] x__h14479, x__h2058;
  wire [1 : 0] x__h1873;
  wire fn_decompress_inst_BIT_10_AND_fn_decompress_in_ETC___d277,
       fn_decompress_inst_BIT_5_4_AND_fn_decompress_i_ETC___d288;

  // value method fn_decompress
  assign fn_decompress =
	     (fn_decompress_inst[15:12] == 4'b0001 &&
	      fn_decompress_inst[1:0] == 2'b0 ||
	      fn_decompress_inst[15:13] == 3'b0 &&
	      (fn_decompress_inst[11] || fn_decompress_inst[10] ||
	       fn_decompress_inst[9] ||
	       fn_decompress_inst[8] ||
	       fn_decompress_inst[7] ||
	       fn_decompress_inst[6] ||
	       fn_decompress_inst[5]) &&
	      fn_decompress_inst[1:0] == 2'b0) ?
	       { 2'd0, x__h1408, 10'd65, fn_decompress_inst[4:2], 7'd19 } :
	       ((fn_decompress_inst[15:13] == 3'b010 &&
		 fn_decompress_inst[1:0] == 2'b0) ?
		  { 5'd0,
		    x__h1569,
		    2'b01,
		    fn_decompress_inst[9:7],
		    5'b01001,
		    fn_decompress_inst[4:2],
		    7'd3 } :
		  IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b11_2__ETC___d346) ;

  // remaining internal signals
  assign IF_fn_decompress_inst_BITS_15_TO_11_11_EQ_0b10_ETC___d320 =
	     (fn_decompress_inst[15:11] == 5'b10011 &&
	      fn_decompress_inst[6:0] == 7'b0000010 ||
	      fn_decompress_inst[15:12] == 4'b1001 &&
	      fn_decompress_inst_BIT_10_AND_fn_decompress_in_ETC___d277) ?
	       { 12'd0, fn_decompress_inst[11:7], 15'd231 } :
	       IF_fn_decompress_inst_BITS_15_TO_12_EQ_0b1001__ETC___d319 ;
  assign IF_fn_decompress_inst_BITS_15_TO_11_11_EQ_0b10_ETC___d323 =
	     (fn_decompress_inst[15:11] == 5'b10001 &&
	      fn_decompress_inst[6:0] == 7'b0000010 ||
	      fn_decompress_inst[15:12] == 4'b1000 &&
	      fn_decompress_inst_BIT_10_AND_fn_decompress_in_ETC___d277) ?
	       { 12'd0, fn_decompress_inst[11:7], 15'd103 } :
	       IF_fn_decompress_inst_BITS_15_TO_12_EQ_0b1000__ETC___d322 ;
  assign IF_fn_decompress_inst_BITS_15_TO_12_EQ_0b1000__ETC___d322 =
	     (fn_decompress_inst[15:12] == 4'b1000 &&
	      (fn_decompress_inst[6] && fn_decompress_inst[1:0] == 2'b10 ||
	       fn_decompress_inst_BIT_5_4_AND_fn_decompress_i_ETC___d288)) ?
	       { 7'b0,
		 fn_decompress_inst[6:2],
		 8'd0,
		 fn_decompress_inst[11:7],
		 7'd51 } :
	       ((fn_decompress_inst == 16'b1001000000000010) ?
		  32'd1048691 :
		  IF_fn_decompress_inst_BITS_15_TO_11_11_EQ_0b10_ETC___d320) ;
  assign IF_fn_decompress_inst_BITS_15_TO_12_EQ_0b1001__ETC___d319 =
	     (fn_decompress_inst[15:12] == 4'b1001 &&
	      (fn_decompress_inst[6] && fn_decompress_inst[1:0] == 2'b10 ||
	       fn_decompress_inst_BIT_5_4_AND_fn_decompress_i_ETC___d288)) ?
	       { 7'b0,
		 fn_decompress_inst[6:2],
		 fn_decompress_inst[11:7],
		 3'b0,
		 fn_decompress_inst[11:7],
		 7'd51 } :
	       IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b110_8_ETC___d318 ;
  assign IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b100_8_ETC___d336 =
	     (fn_decompress_inst[15:13] == 3'b100 &&
	      fn_decompress_inst[11:10] == 2'b10 &&
	      fn_decompress_inst[1:0] == 2'b01) ?
	       { SEXT_fn_decompress_inst_BIT_12_0_CONCAT_fn_dec_ETC___d67,
		 2'b01,
		 fn_decompress_inst[9:7],
		 5'b11101,
		 fn_decompress_inst[9:7],
		 7'd19 } :
	       ((fn_decompress_inst[15:10] == 6'b100011 &&
		 fn_decompress_inst[6:5] == 2'b0 &&
		 fn_decompress_inst[1:0] == 2'b01) ?
		  { 9'b010000001,
		    fn_decompress_inst[4:2],
		    2'b01,
		    fn_decompress_inst[9:7],
		    5'b00001,
		    fn_decompress_inst[9:7],
		    7'd51 } :
		  ((fn_decompress_inst[15:10] == 6'b100011 &&
		    fn_decompress_inst[6:5] == 2'b01 &&
		    fn_decompress_inst[1:0] == 2'b01) ?
		     { 9'b000000001,
		       fn_decompress_inst[4:2],
		       2'b01,
		       fn_decompress_inst[9:7],
		       5'b10001,
		       fn_decompress_inst[9:7],
		       7'd51 } :
		     ((fn_decompress_inst[15:10] == 6'b100011 &&
		       fn_decompress_inst[6:5] == 2'b10 &&
		       fn_decompress_inst[1:0] == 2'b01) ?
			{ 9'b000000001,
			  fn_decompress_inst[4:2],
			  2'b01,
			  fn_decompress_inst[9:7],
			  5'b11001,
			  fn_decompress_inst[9:7],
			  7'd51 } :
			((fn_decompress_inst[15:10] == 6'b100011 &&
			  fn_decompress_inst[6:5] == 2'b11 &&
			  fn_decompress_inst[1:0] == 2'b01) ?
			   { 9'b000000001,
			     fn_decompress_inst[4:2],
			     2'b01,
			     fn_decompress_inst[9:7],
			     5'b11101,
			     fn_decompress_inst[9:7],
			     7'd51 } :
			   ((fn_decompress_inst[15:10] == 6'b100111 &&
			     fn_decompress_inst[6:5] == 2'b0 &&
			     fn_decompress_inst[1:0] == 2'b01) ?
			      { 9'b010000001,
				fn_decompress_inst[4:2],
				2'b01,
				fn_decompress_inst[9:7],
				5'b00001,
				fn_decompress_inst[9:7],
				7'd59 } :
			      ((fn_decompress_inst[15:10] == 6'b100111 &&
				fn_decompress_inst[6:5] == 2'b01 &&
				fn_decompress_inst[1:0] == 2'b01) ?
				 { 9'b000000001,
				   fn_decompress_inst[4:2],
				   2'b01,
				   fn_decompress_inst[9:7],
				   5'b00001,
				   fn_decompress_inst[9:7],
				   7'd59 } :
				 ((fn_decompress_inst[15:13] == 3'b101 &&
				   fn_decompress_inst[1:0] == 2'b01) ?
				    { fn_decompress_inst[12],
				      fn_decompress_inst[8],
				      fn_decompress_inst[10:9],
				      fn_decompress_inst[6],
				      fn_decompress_inst[7],
				      fn_decompress_inst[2],
				      fn_decompress_inst[11],
				      fn_decompress_inst[5:3],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      fn_decompress_inst[12],
				      12'd111 } :
				    ((fn_decompress_inst[15:13] == 3'b110 &&
				      fn_decompress_inst[1:0] == 2'b01) ?
				       { fn_decompress_inst[12],
					 fn_decompress_inst[12],
					 fn_decompress_inst[12],
					 fn_decompress_inst[12],
					 fn_decompress_inst[6:5],
					 fn_decompress_inst[2],
					 7'b0000001,
					 fn_decompress_inst[9:7],
					 3'b0,
					 fn_decompress_inst[11:10],
					 fn_decompress_inst[4:3],
					 fn_decompress_inst[12],
					 7'd99 } :
				       ((fn_decompress_inst[15:13] ==
					 3'b111 &&
					 fn_decompress_inst[1:0] == 2'b01) ?
					  { fn_decompress_inst[12],
					    fn_decompress_inst[12],
					    fn_decompress_inst[12],
					    fn_decompress_inst[12],
					    fn_decompress_inst[6:5],
					    fn_decompress_inst[2],
					    7'b0000001,
					    fn_decompress_inst[9:7],
					    3'b001,
					    fn_decompress_inst[11:10],
					    fn_decompress_inst[4:3],
					    fn_decompress_inst[12],
					    7'd99 } :
					  ((fn_decompress_inst[15:13] ==
					    3'b0 &&
					    fn_decompress_inst[1:0] ==
					    2'b10) ?
					     { 6'b0,
					       fn_decompress_inst[12],
					       fn_decompress_inst[6:2],
					       fn_decompress_inst[11:7],
					       3'b001,
					       fn_decompress_inst[11:7],
					       7'd19 } :
					     IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b10_2__ETC___d325)))))))))) ;
  assign IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b10_2__ETC___d325 =
	     (fn_decompress_inst[15:13] == 3'b010 &&
	      (fn_decompress_inst[11] || fn_decompress_inst[10] ||
	       fn_decompress_inst[9] ||
	       fn_decompress_inst[8] ||
	       fn_decompress_inst[7]) &&
	      fn_decompress_inst[1:0] == 2'b10) ?
	       { 4'd0, x__h12096, 8'd18, fn_decompress_inst[11:7], 7'd3 } :
	       ((fn_decompress_inst[15:13] == 3'b011 &&
		 fn_decompress_inst[1:0] == 2'b10) ?
		  { 3'd0, x__h12235, 8'd19, fn_decompress_inst[11:7], 7'd3 } :
		  IF_fn_decompress_inst_BITS_15_TO_11_11_EQ_0b10_ETC___d323) ;
  assign IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b110_8_ETC___d318 =
	     (fn_decompress_inst[15:13] == 3'b110 &&
	      fn_decompress_inst[1:0] == 2'b10) ?
	       { 4'd0,
		 x__h14479,
		 fn_decompress_inst[6:2],
		 8'd18,
		 fn_decompress_inst[11:9],
		 9'd35 } :
	       ((fn_decompress_inst[15:13] == 3'b111 &&
		 fn_decompress_inst[1:0] == 2'b10) ?
		  { 3'd0,
		    x__h14618,
		    fn_decompress_inst[6:2],
		    8'd19,
		    fn_decompress_inst[11:10],
		    10'd35 } :
		  { 16'd0, fn_decompress_inst }) ;
  assign IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b111_7_ETC___d344 =
	     (fn_decompress_inst[15:13] == 3'b111 &&
	      fn_decompress_inst[1:0] == 2'b0) ?
	       { 4'd0,
		 x__h2058,
		 2'b01,
		 fn_decompress_inst[4:2],
		 2'b01,
		 fn_decompress_inst[9:7],
		 3'b011,
		 fn_decompress_inst[11:10],
		 10'd35 } :
	       ((fn_decompress_inst[15:13] == 3'b0 &&
		 fn_decompress_inst[1:0] == 2'b01) ?
		  { SEXT_fn_decompress_inst_BIT_12_0_CONCAT_fn_dec_ETC___d67,
		    fn_decompress_inst[11:7],
		    3'b0,
		    fn_decompress_inst[11:7],
		    7'd19 } :
		  IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b1_2_A_ETC___d342) ;
  assign IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b11_2__ETC___d346 =
	     (fn_decompress_inst[15:13] == 3'b011 &&
	      fn_decompress_inst[1:0] == 2'b0) ?
	       { 4'd0,
		 x__h1733,
		 2'b01,
		 fn_decompress_inst[9:7],
		 5'b01101,
		 fn_decompress_inst[4:2],
		 7'd3 } :
	       ((fn_decompress_inst[15:13] == 3'b110 &&
		 fn_decompress_inst[1:0] == 2'b0) ?
		  { 5'd0,
		    x__h1873,
		    2'b01,
		    fn_decompress_inst[4:2],
		    2'b01,
		    fn_decompress_inst[9:7],
		    3'b010,
		    fn_decompress_inst[11:10],
		    fn_decompress_inst[6],
		    9'd35 } :
		  IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b111_7_ETC___d344) ;
  assign IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b1_2_A_ETC___d342 =
	     (fn_decompress_inst[15:13] == 3'b001 &&
	      (fn_decompress_inst[11] || fn_decompress_inst[10] ||
	       fn_decompress_inst[9] ||
	       fn_decompress_inst[8] ||
	       fn_decompress_inst[7]) &&
	      fn_decompress_inst[1:0] == 2'b01) ?
	       { SEXT_fn_decompress_inst_BIT_12_0_CONCAT_fn_dec_ETC___d67,
		 fn_decompress_inst[11:7],
		 3'b0,
		 fn_decompress_inst[11:7],
		 7'd27 } :
	       ((fn_decompress_inst[15:13] == 3'b010 &&
		 fn_decompress_inst[1:0] == 2'b01) ?
		  { SEXT_fn_decompress_inst_BIT_12_0_CONCAT_fn_dec_ETC___d67,
		    8'd0,
		    fn_decompress_inst[11:7],
		    7'd19 } :
		  IF_fn_decompress_inst_BITS_15_TO_7_3_EQ_0b1110_ETC___d340) ;
  assign IF_fn_decompress_inst_BITS_15_TO_7_3_EQ_0b1110_ETC___d340 =
	     (fn_decompress_inst[15:7] == 9'b011100010 &&
	      fn_decompress_inst[1:0] == 2'b01 ||
	      fn_decompress_inst[15:13] == 3'b011 &&
	      (fn_decompress_inst[11:6] == 6'b000101 &&
	       fn_decompress_inst[1:0] == 2'b01 ||
	       fn_decompress_inst[11:7] == 5'b00010 &&
	       (fn_decompress_inst[5] && fn_decompress_inst[1:0] == 2'b01 ||
		fn_decompress_inst[4] && fn_decompress_inst[1:0] == 2'b01 ||
		fn_decompress_inst[3] && fn_decompress_inst[1:0] == 2'b01 ||
		fn_decompress_inst[2:0] == 3'b101))) ?
	       { { {2{x__h4254[9]}}, x__h4254 }, 20'd65811 } :
	       ((fn_decompress_inst[15:11] == 5'b01111 &&
		 fn_decompress_inst[1:0] == 2'b01 ||
		 fn_decompress_inst[15:12] == 4'b0111 &&
		 fn_decompress_inst[10] &&
		 fn_decompress_inst[1:0] == 2'b01 ||
		 fn_decompress_inst[15:12] == 4'b0111 &&
		 fn_decompress_inst[9] &&
		 fn_decompress_inst[1:0] == 2'b01 ||
		 fn_decompress_inst[15:12] == 4'b0111 &&
		 !fn_decompress_inst[8] &&
		 fn_decompress_inst[1:0] == 2'b01 ||
		 fn_decompress_inst[15:12] == 4'b0111 &&
		 fn_decompress_inst[7] &&
		 fn_decompress_inst[1:0] == 2'b01 ||
		 fn_decompress_inst[15:13] == 3'b011 &&
		 (fn_decompress_inst[11] && fn_decompress_inst[6] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[10] && fn_decompress_inst[6] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[9] && fn_decompress_inst[6] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  !fn_decompress_inst[8] && fn_decompress_inst[6] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[7:6] == 2'b11 &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[11] && fn_decompress_inst[5] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[10] && fn_decompress_inst[5] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[9] && fn_decompress_inst[5] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  !fn_decompress_inst[8] && fn_decompress_inst[5] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[7] && fn_decompress_inst[5] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[11] && fn_decompress_inst[4] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[10] && fn_decompress_inst[4] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[9] && fn_decompress_inst[4] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  !fn_decompress_inst[8] && fn_decompress_inst[4] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[7] && fn_decompress_inst[4] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[11] && fn_decompress_inst[3] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[10] && fn_decompress_inst[3] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[9] && fn_decompress_inst[3] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  !fn_decompress_inst[8] && fn_decompress_inst[3] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  fn_decompress_inst[7] && fn_decompress_inst[3] &&
		  fn_decompress_inst[1:0] == 2'b01 ||
		  (fn_decompress_inst[11] || fn_decompress_inst[10] ||
		   fn_decompress_inst[9] ||
		   !fn_decompress_inst[8] ||
		   fn_decompress_inst[7]) &&
		  fn_decompress_inst[2:0] == 3'b101)) ?
		  { { {14{fn_decompress_inst_BIT_12_CONCAT_fn_decompress_ETC__q1[5]}},
		      fn_decompress_inst_BIT_12_CONCAT_fn_decompress_ETC__q1 },
		    fn_decompress_inst[11:7],
		    7'd55 } :
		  ((fn_decompress_inst[15:13] == 3'b100 &&
		    fn_decompress_inst[11:10] == 2'b0 &&
		    fn_decompress_inst[1:0] == 2'b01) ?
		     { 6'b0,
		       fn_decompress_inst[12],
		       fn_decompress_inst[6:2],
		       2'b01,
		       fn_decompress_inst[9:7],
		       5'b10101,
		       fn_decompress_inst[9:7],
		       7'd19 } :
		     ((fn_decompress_inst[15:13] == 3'b100 &&
		       fn_decompress_inst[11:10] == 2'b01 &&
		       fn_decompress_inst[1:0] == 2'b01) ?
			{ 6'b010000,
			  fn_decompress_inst[12],
			  fn_decompress_inst[6:2],
			  2'b01,
			  fn_decompress_inst[9:7],
			  5'b10101,
			  fn_decompress_inst[9:7],
			  7'd19 } :
			IF_fn_decompress_inst_BITS_15_TO_13_EQ_0b100_8_ETC___d336))) ;
  assign SEXT_fn_decompress_inst_BIT_12_0_CONCAT_fn_dec_ETC___d67 =
	     { {6{fn_decompress_inst_BIT_12_CONCAT_fn_decompress_ETC__q1[5]}},
	       fn_decompress_inst_BIT_12_CONCAT_fn_decompress_ETC__q1 } ;
  assign fn_decompress_inst_BIT_10_AND_fn_decompress_in_ETC___d277 =
	     fn_decompress_inst[10] &&
	     fn_decompress_inst[6:0] == 7'b0000010 ||
	     fn_decompress_inst[9] && fn_decompress_inst[6:0] == 7'b0000010 ||
	     fn_decompress_inst[8] && fn_decompress_inst[6:0] == 7'b0000010 ||
	     fn_decompress_inst[7:0] == 8'b10000010 ;
  assign fn_decompress_inst_BIT_12_CONCAT_fn_decompress_ETC__q1 =
	     { fn_decompress_inst[12], fn_decompress_inst[6:2] } ;
  assign fn_decompress_inst_BIT_5_4_AND_fn_decompress_i_ETC___d288 =
	     fn_decompress_inst[5] && fn_decompress_inst[1:0] == 2'b10 ||
	     fn_decompress_inst[4] && fn_decompress_inst[1:0] == 2'b10 ||
	     fn_decompress_inst[3] && fn_decompress_inst[1:0] == 2'b10 ||
	     fn_decompress_inst[2:0] == 3'b110 ;
  assign x__h12096 =
	     { fn_decompress_inst[3:2],
	       fn_decompress_inst[12],
	       fn_decompress_inst[6:4],
	       2'd0 } ;
  assign x__h12235 =
	     { fn_decompress_inst[4:2],
	       fn_decompress_inst[12],
	       fn_decompress_inst[6:5],
	       3'd0 } ;
  assign x__h1408 =
	     { fn_decompress_inst[10:7],
	       fn_decompress_inst[12:11],
	       fn_decompress_inst[5],
	       fn_decompress_inst[6],
	       2'd0 } ;
  assign x__h14479 = { fn_decompress_inst[8:7], fn_decompress_inst[12] } ;
  assign x__h14618 = { fn_decompress_inst[9:7], fn_decompress_inst[12] } ;
  assign x__h1569 =
	     { fn_decompress_inst[5],
	       fn_decompress_inst[12:10],
	       fn_decompress_inst[6],
	       2'd0 } ;
  assign x__h1733 =
	     { fn_decompress_inst[6:5], fn_decompress_inst[12:10], 3'd0 } ;
  assign x__h1873 = { fn_decompress_inst[5], fn_decompress_inst[12] } ;
  assign x__h2058 = { fn_decompress_inst[6:5], fn_decompress_inst[12] } ;
  assign x__h4254 =
	     { fn_decompress_inst[12],
	       fn_decompress_inst[4:3],
	       fn_decompress_inst[5],
	       fn_decompress_inst[2],
	       fn_decompress_inst[6],
	       4'd0 } ;
endmodule  // module_fn_decompress
