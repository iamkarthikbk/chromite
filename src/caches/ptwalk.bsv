/* 
Copyright (c) 2018, IIT Madras All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions
  and the following disclaimer.  
* Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and/or other materials provided 
 with the distribution.  
* Neither the name of IIT Madras  nor the names of its contributors may be used to endorse or 
  promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------------------------

Author: Neel Gala
Email id: neelgala@gmail.com
Details:

--------------------------------------------------------------------------------------------------
*/
package ptwalk;
  import Vector::*;
  import FIFOF::*;
  import DReg::*;
  import SpecialFIFOs::*;
  import BRAMCore::*;
  import FIFO::*;
  import GetPut::*;

  import common_types::*;

  interface Ifc_ptwalk#(numeric type asid_width,
                        numeric type ptesize);
    interface Put#(Tuple2#(Bit#(ptesize),Bit#(2))) from_tlb;
                          // ppn   , levels , trap
    interface Get#(Tuple3#(Bit#(ptesize),Bit#(1),Trap_type)) to_tlb;
    interface Put#(Bit#(XLEN)) satp_from_csr;
    interface Put#(Bit#(2)) curr_priv;
  endinterface

  module mkptwalk(Ifc_ptwalk#(asid_width,ptesize));
    FIFOF#(Tuple2#(Bit#(ptesize),Bit#(2))) ff_req_queue<-mkSizedFIFOF(2);
    FIFOF#(Tuple3#(Bit#(ptesize),Bit#(1),Trap_type)) ff_response<-mkSizedFIFOF(2);
    // wire which hold the inputs from csr
    Wire#(Bit#(XLEN)) wr_satp <- mkWire();
    Wire#(Bit#(2)) wr_priv <- mkWire();

    interface from_tlb=interface Put
      method Action put(Tuple2#(Bit#(ptesize),Bit#(2)) req);
        ff_req_queue.enq(req);
      endmethod
    endinterface;

    interface to_tlb=interface Get
      method ActionValue#(Tuple3#(Bit#(ptesize),Bit#(1),Trap_type)) get;
        ff_response.deq;
        return ff_response.first();
      endmethod
    endinterface;

    interface satp_from_csr=interface Put
      method Action put (Bit#(XLEN) satp);
        wr_satp<=satp;
      endmethod
    endinterface;

    interface curr_priv = interface Put
      method Action put (Bit#(2) priv);
        wr_priv<=priv;
      endmethod
    endinterface;

  endmodule

  (*synthesize*)
  module mkinstance(Ifc_ptwalk#(9,32));
    let ifc();
    mkptwalk _temp(ifc);
    return (ifc);
  endmodule
endpackage

