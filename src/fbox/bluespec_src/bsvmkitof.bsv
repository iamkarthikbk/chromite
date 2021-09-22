// Bluespec wrapper, created by Import BVI Wizard
// Created on: Sat Dec 28 13:15:12 IST 2019
// Created by: sugandha
// Bluespec version: 2019.05.beta2 2019-05-24 a88bf40db


interface Ifc_itof#(numeric type expWidth, numeric type sigWidth, numeric type intWidth);
	(*always_enabled*)
	method Bit#(TAdd#(expWidth, sigWidth)) oout ();
	(*always_enabled*)
	method Bit#(5) oexceptionFlags ();
	(*always_ready , always_enabled*)
	method Action request (Bit#(1) control, Bit#(3) roundingmode, Bit#(1) signedout, Bit#(intWidth) a);
endinterface

import "BVI" itof =
module mkitof  (Ifc_itof#(expWidth, sigWidth, intWidth));

	default_clock clk_clk;
	default_reset rst;
	
	parameter expWidth = valueOf(expWidth);
  parameter sigWidth = valueOf(sigWidth);
  parameter intWidth = valueOf(intWidth);

	input_clock clk_clk (clk)  <- exposeCurrentClock;
	input_reset rst (/* empty */) clocked_by(clk_clk)  <- exposeCurrentReset;


	method out /* (expWidth+sigWidth-1) : 0 */ oout ()
		 clocked_by(clk_clk) reset_by(rst);
	method exceptionFlags /* 4 : 0 */ oexceptionFlags ()
		 clocked_by(clk_clk) reset_by(rst);
	method request (control , roundingMode /*2:0*/, signedOut , a /*(intWidth-1):0*/)
		 enable((*inhigh*)request_enable) clocked_by(clk_clk) reset_by(rst);

	schedule oout CF oout;
	schedule oout CF oexceptionFlags;
	schedule oout SB request;
	schedule oexceptionFlags CF oexceptionFlags;
	schedule oexceptionFlags SB request;
	schedule request C request;
endmodule


