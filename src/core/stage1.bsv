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

Author: Neel Gala, Vipul, Deepa
Email id: neelgala@gmail.com
Details:
This module will interact with the memory subsystem to fetch relevant instructions from memory. The
module will also receive flushes from the write-back stage which could be because of a fence or trap
handling. 
TODO: Add support to interact with Branch predictor.
TODO: Currently the cache responds only with bus-error. In case of supervisor mode the cache is
expected to respond if a page-fault occurred for the said request and thus the error response will
be 2 bits wide instead of the current 1-bit.
--------------------------------------------------------------------------------------------------
*/
package stage1;
  // -- package imports --//
  import FIFOF::*;
  import SpecialFIFOs::*;
  import FIFO::*;
  import GetPut::*;
  import Assert::*;

  // -- local imports --//
	import TxRx	::*;
  import common_types::*;
  `include "common_params.bsv"
  `include "Logger.bsv"
  
  // Enum to define the action to be taken when an instruction arrives.
  typedef enum {CheckPrev, None} ActionType deriving(Bits,Eq,FShow);

	interface Ifc_stage1;

    // instruction response from the memory subsytem or the memory bus
    //                     inst , trap, cause, epoch 
    interface Put#(Tuple4#(Bit#(32),Bool,Bit#(6),Bit#(`iesize))) inst_response;

  `ifdef branch_speculation
    interface Put#(PredictionResponse) prediction_response;
  `endif

    // instruction along with other results to be sent to the next stage
    interface TXe#(PIPE1) tx_next_stage;

    // method to update epochs on redirection from execute stage
		method Action update_eEpoch;
    
      // method to update epochs on redirection from writeback stage
		method Action update_wEpoch;

    // csrs from the csrfile.
    method Action csr_misa_c (Bit#(1) c);

	endinterface

  (*synthesize*)
  module mkstage1(Ifc_stage1);
    String stage1="";
    let verbosity = `VERBOSITY ;
    
    // this wire carries the current values of certain csrs.
    Wire#(Bit#(1)) wr_csr_misa_c <-mkWire();

    // The following registers are use to the maintain epochs from various pipeline stages:
    // writeback, execute stage and fetch stage.
    Reg#(Bit#(1)) rg_wEpoch <- mkReg(0);
    Reg#(Bit#(1)) rg_eEpoch <- mkReg(0);

    // This register implements a simple state-machine which indicates how the instruction should be
    // extracted from the cache response.
    Reg#(ActionType) rg_action <- mkReg(None);

    // This register indicates that the lower 16-bits of the response from the cache need to be
    // ignored. This happens because, when there is jump to non-4-byte aligned address the cache
    // still receives a previous 4-byte-ailgned address from the fetch stage.
    Reg#(Bool) rg_discard_lower <- mkReg(False);
    Reg#(Bool) rg_receiving_upper <- mkReg(False);

    // This register holds the 16-bits of instruction from the previous cache response if required.
    Reg#(Bit#(16)) rg_instruction <- mkReg(0);
  `ifdef branch_speculation
    `ifdef compressed
      Reg#(Bit#(2)) rg_prediction <- mkReg(0);
      Reg#(Bit#(`vaddr)) rg_pc <- mkReg(0);
    `endif
  `endif

    // This FIFO receives the response from the memory subsytem (a.k.a cache)
    FIFOF#(Tuple4#(Bit#(32),Bool,Bit#(6),Bit#(`iesize))) ff_memory_response<-mkBypassFIFOF();

  `ifdef branch_speculation
    FIFOF#(PredictionResponse) ff_prediction_resp <- mkBypassFIFOF();
  `endif

    // FIFO to interface with the next pipeline stage
		TX#(PIPE1) tx<-mkTX;

    // RuleName: process_instruction
    // Explicit Conditions: None
    // Implicit Conditions: 
    //    1. ff_memory_response.notEmpty
    //    2. wr_csr is written in the same cycle
    //    3. tostage FIFO notFull
    // Schedule Conflicts: This rule will not fire if there is flush from the write-back stage. A
    // flush from the write-back stage will cause a change in the rg_pc and rg_discard_lower,
    // both of which are being updated in this method as well. This schedule is acceptable since
    // anyways the response from the memory currently to be handled in this rule will match epochs
    // and will be dropped.
    //
    // Details: This rule will receive the instruction from the memory subsystem and decide if the
    // instruction is compressed or not. The final instruction is then sent to the next stage.
    // To extract the instruction from the memory response a state machine is implemented.
    // 
    // 1. First the epochs are compared and if a mis-match is observed then the response is dropped
    // without any other changes to the state of the module.
    // 2. if rg_discard_lower is set and compressed is enabled then the lower 16-bits of the
    // resposne are discarded and the upper 16-bits are probed to check if it is a compressed
    // instruction. If so, then the instruction is sent to the next stage. However is it is not a
    // compressed instruction it means the upper 16-bits of the response refer to the lower 16-bits
    // of a 32-bit instruction and thus we will have to wait for the next response from the cache to
    // form the instruction is send to the next stage. To ensure the concatenation happens in the
    // next response we set rg_action to ChecPrev and set enque_instruction to False.
    // 3. if rg_action is set to None, then we simply probe the lower 2-bits to the response to
    // check if it is compressed. If so then the lower 16 bits form an instruction which is sent to
    // the next stage, the upper 16-bits are stored to rg_instruction and rg_action is set to
    // CheckPrev to ensure that in the next resposne we first probe rg_instruction.
    // 4. if rg_Action if set to CheckPrev then we first probe the lower 2-bits of the 
    // rg_instruction which leads to two possibilities. Either rg_instruction could hold a
    // compressed instruction from the previous response, in which case the current memory response
    // is not dequed and rg_instruction is sent to the next stage. This can happen due to state-3
    // mentioned above. The other possibility is that rg_instruction holds the lower 16-bits of a
    // 32-bit isntruction, in which case we have concatenate the lower 16-bits of the response with
    // rg_instruction and send to the next, and also store the upper 16-bits of the response into
    // rg_instruction. rg_Action in this case will remain CheckPrev so that the upper bits of this
    // repsonse are probed in the next cycle.
    rule process_instruction;
      `ifdef branch_speculation
        `ifdef compressed
          let {prediction0,prediction1, va, discard_lower} = ff_prediction_resp.first();
          Bit#(2) prediction=prediction0;
        `else
          let {prediction,va} = ff_prediction_resp.first();
        `endif
        `logLevel( stage1,1,$format("STAGE1: Prediction: ",fshow(ff_prediction_resp.first)))
        `logLevel( stage1,1,$format("STAGE1: rg_prediction:%b rg_pc:%h rg_instruction:%h",rg_prediction, rg_pc,  rg_instruction))
      `endif
        let {cache_response,err,cause,epoch}=ff_memory_response.first;
        Bit#(32) final_instruction=0;
        Bool compressed=False;
        Bool enque_instruction=True;
        // if epochs do not match then drop the instruction
        if({rg_eEpoch,rg_wEpoch}!=epoch)begin
          ff_memory_response.deq;
        `ifdef branch_speculation
          ff_prediction_resp.deq;
        `endif
          rg_action<=None;
          enque_instruction=False;
          `logLevel( stage1,1,$format("STAGE1: Dropping Instruction"))
        end
        else if(discard_lower && wr_csr_misa_c==1)begin
          ff_memory_response.deq;
        `ifdef branch_speculation
          ff_prediction_resp.deq;
        `endif
          if(cache_response[17:16]==2'b11)begin
            rg_instruction<=cache_response[31:16];
            rg_action<=CheckPrev;
            enque_instruction=False;
            rg_receiving_upper<=True;
          `ifdef compressed
            rg_prediction<= prediction1;
            rg_pc<= va;
          `endif
          end
          else begin
            compressed=True;
            final_instruction=zeroExtend(cache_response[31:16]);
          `ifdef compressed
            va[1]=1;
            prediction=prediction1;
          `endif
          end
        end
        else if(rg_action == None)begin
          // No updates to va required
          ff_memory_response.deq;
        `ifdef branch_speculation
          ff_prediction_resp.deq;
        `endif
          if(cache_response[1:0]=='b11)begin
            final_instruction=cache_response;
          `ifdef compressed
            prediction=prediction0;
          `endif
          end
          else if(wr_csr_misa_c==1) begin
            compressed=True;
            final_instruction=zeroExtend(cache_response[15:0]);
            rg_instruction<=truncateLSB(cache_response);
          `ifdef compressed
            rg_action<=prediction0==0?CheckPrev:None;
            prediction=prediction0;
            rg_prediction<= prediction1;
            rg_pc<= va;
          `else
            rg_action<=CheckPrev;
          `endif
          end
        end
        else begin
        `ifdef compressed
          prediction=rg_prediction;
        `endif
          if(rg_instruction[1:0]==2'b11)begin
            final_instruction={cache_response[15:0],rg_instruction};
            rg_instruction<=truncateLSB(cache_response);
            rg_pc<=va;
            ff_memory_response.deq;
          `ifdef branch_speculation
            ff_prediction_resp.deq;
          `endif
            if(rg_receiving_upper)
              rg_receiving_upper<=False;
            `ifdef compressed
              va=rg_pc;
              va[1]=1;
            `endif
          end
          else begin
            compressed=True;
            final_instruction=zeroExtend(rg_instruction);
            rg_action<=None;
            `ifdef compressed
              va=rg_pc;
              va[1]=1;
            `endif
          end
        end
        Bit#(`vaddr) incr_value = (compressed  && wr_csr_misa_c==1)?2:4;
				let pipedata=PIPE1{program_counter:va,
                      instruction:final_instruction,
                      epochs:{rg_eEpoch,rg_wEpoch},
                      trap: err
                    `ifdef branch_speculation
                      ,prediction:prediction
                    `endif
                    `ifdef compressed
                      ,upper_err:rg_receiving_upper&&err
                    `endif
                    `ifdef supervisor
                      ,cause:cause
                    `endif }; 
        `logLevel( stage1,0,$format("STAGE1: Analysing PC:%h : ",va,fshow(ff_memory_response.first)))
        `logLevel( stage1,1,$format("STAGE1: rg_action: ",fshow(rg_action)," misa[c]:%b discard:%b", wr_csr_misa_c,discard_lower))
        if(enque_instruction) begin
          tx.u.enq(pipedata);
          `logLevel( stage1,0,$format("STAGE1: Enquing to Next Stage: ",fshow(pipedata)))
        end
    endrule

    // This method will capture the response from the memory subsytem and enque it in a FIFO.
    // Explicit Conditions: None
    // Implicit Conditions: ff_memory_response.notFull
    // Description: One could of think of performing all the function in the process_instruction
    // rule in this method itself. This would only work if you are not supporting compressed
    // instructions. When you support compressed, the cache can send a single response which
    // contains 2 16-bit instruction. In such a case the process_instruction rule will fire twice
    // and deque the fifo only on the second run. Thus we need to have a fifo which will store the
    // response from the cache for an extra cycle. 
    // The former approach could work with compressed as well if : we process both the instructions
    // and enqueue them simultaneously into the next stage. Not sure what other dependencies would
    // be there?
		interface inst_response= interface Put
			method Action put (Tuple4#(Bit#(32),Bool,Bit#(6),Bit#(`iesize)) resp);
        `logLevel( stage1,1,$format("STAGE1: Recevied from IMEM: ",fshow(resp)))
        ff_memory_response.enq(resp);
			endmethod
    endinterface;
  
  `ifdef branch_speculation
    interface prediction_response = interface Put
      method Action put(PredictionResponse p);
        `logLevel( stage1,1,$format("STAGE1: Recevied Prediction: ",fshow(p)))
        ff_prediction_resp.enq(p);
      endmethod
    endinterface;
  `endif
    
		interface tx_next_stage = tx.e;

    // MethodName: update_eEpoch
    // Explicit Conditions: None
    // Implicit Conditions: None 
    method Action update_eEpoch;
      rg_eEpoch<=~rg_eEpoch;
    endmethod

    // MethodName: update_wEpoch
    // Explicit Conditions: None
    // Implicit Conditions: None 
    method Action update_wEpoch;
      rg_wEpoch<=~rg_wEpoch;
    endmethod
    
    // This method captures the "c" of misa csr
    method Action csr_misa_c (Bit#(1) c);
      wr_csr_misa_c <= c;
    endmethod
  endmodule
endpackage

