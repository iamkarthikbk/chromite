/* 
Copyright (c) 2018, IIT Madras All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions
  and the following disclaimer.  
* Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and / or other materials provided 
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

Author : Neel Gala
Email id : neelgala@gmail.com
Details:

--------------------------------------------------------------------------------------------------
*/
package bimodal;
	/*===== Pacakge imports ===== */
	import FIFO::*;
	import FIFOF::*;
	import SpecialFIFOs::*;
	import ConfigReg::*;
	import Connectable::*;
	import GetPut::*;
  import Assert::*;
  
  /*==== Project imports ======= */
  import mem_config::*; // for bram 1rw instances.
  import globals::*;
  `include "Logger.bsv"
`ifdef ras
  import stack::*;
`endif

  `ifdef compressed
    `define ignore 2
  `else
    `define ignore 2
  `endif

  typedef Tuple3#(Bit#(`vaddr), Bit#(`vaddr), Bit#(2)) Training_data;

	interface Ifc_bimodal;
    // method to receive the new pc for which prediction is to be looked up.
		method Action prediction_req(PredictionRequest req);

    // method to respond to stage0 with prediction state and new target address on hit
		interface Get#(PredictionResponse) prediction_response; 

    // method to training the BTB and BHT tables
		method Action train_bpu (Training_data td);

    method PredictionToStage0 predicted_pc;
  `ifdef ras
    method Action train_ras(Bit#(`vaddr) pc);
    method Action ras_push(Bit#(`vaddr) pc);
  `endif
	endinterface

	(*synthesize*)
	module mkbimodal(Ifc_bimodal);
    String bimodal="";
    Ifc_mem_config1r1w#(TDiv#(`btbsize, 2) , `vaddr, 1) mem_btb0 <- mkmem_config1r1w(False,"double");
    Ifc_mem_config1r1w#(TDiv#(`btbsize, 2) , `vaddr, 1) mem_btb1 <- mkmem_config1r1w(False,"double");

    // ram to hold the tag of the address being predicted. The 2 bits are deducted since we are
    // supporting only non - compressed ISA. When compressed is supported, 1 will be dedudcted.
    Ifc_mem_config1r1w#(TDiv#(`btbsize,  2) , 
        TAdd#(TSub#(TSub#(`vaddr, TLog#(`btbsize)),`ignore), 3), 1) mem_btb_tag0 
        <- mkmem_config1r1w(False,"double");
    Ifc_mem_config1r1w#(TDiv#(`btbsize,  2) , 
        TAdd#(TSub#(TSub#(`vaddr, TLog#(`btbsize)),`ignore), 3), 1) mem_btb_tag1 
        <- mkmem_config1r1w(False,"double");

  `ifdef ras 
    // ram to hold the tag bits for return instructions
    Ifc_mem_config1r1w#(TDiv#(`rassets, 2), 
        TAdd#(TSub#(TSub#(`vaddr, TLog#(`rassets )), `ignore), 1), 1) mem_ras_tag0
        <- mkmem_config1r1w(False,"double");
    Ifc_mem_config1r1w#(TDiv#(`rassets, 2), 
        TAdd#(TSub#(TSub#(`vaddr, TLog#(`rassets )), `ignore), 1), 1) mem_ras_tag1
        <- mkmem_config1r1w(False,"double");

    // stack structure to hold the return addresses
    Ifc_stack#(`vaddr, `rassize) ras_stack <- mkstack;
  `endif

    // boolean register and counter used to initialize the ram structure on reset.
    Reg#(Bool) rg_init <- mkReg(True);
    Reg#(Bit#(TAdd#(1, TLog#(TMax#(TDiv#(`btbsize, 2), TDiv#(`rassets, 2)))))) rg_init_count <- mkReg(0);

    FIFOF#(PredictionRequest)  ff_pred_request      <- mkSizedFIFOF(2);
    FIFOF#(PredictionResponse) ff_prediction_resp   <- mkBypassFIFOF();
    Reg#(PredictionToStage0)   rg_prediction_pc[2]  <- mkCReg(2, PredictionToStage0{prediction : 0,
                                                                                    target_pc : ?});
    
    // RuleName : initialize
    // Explicit Conditions : rg_init == True
    // Implicit Conditions : None
    // on system reset first initialize the ram structure with valid = 0.
    rule initialize(rg_init);
      mem_btb_tag0.write(1, truncate(rg_init_count), 0);
      mem_btb_tag1.write(1, truncate(rg_init_count), 0);
    `ifdef ras
      mem_ras_tag0.write(1, truncate(rg_init_count), 0);
      mem_ras_tag1.write(1, truncate(rg_init_count), 0);
    `endif
      if(rg_init_count == fromInteger(max((`btbsize / 2),(`rassets / 2)))) begin
				rg_init <= False;
			end
      `logLevel( bimodal, 0, $format("Bimodal : Init stage. Count:%d",rg_init_count))
      rg_init_count <= rg_init_count + 1;
		endrule

    // RuleName : perform_prediction
    // Explicit Conditions : None
    // Implicit Conditions : None
    // Description : This rule will the prediction response from the BTB and RAS and send the result
    // to stage1. A hit can occur either in the BTB or the RAS and never both
    rule perform_prediction;
      Bit#(4) hit = 0;
      let request = ff_pred_request.first();
      ff_pred_request.deq();
    `ifdef compressed
      Bit#(2) prediction0 = 0;
      Bit#(2) prediction1 = 0;
      Bit#(2) prediction = 0;
    `else
      Bit#(2) prediction = 1;
    `endif
  
      // extract tag from the request PC for comparison
      Bit#(TSub#(TSub#(`vaddr, TLog#(`btbsize)),`ignore)) btb_tag_cmp = truncateLSB(request.pc);

      // extract the target - address, tags, counter - value and prediction state from bank0
      let bimodal_target_addr0 = mem_btb0.read_response;
      let bht_tag_state0 = mem_btb_tag0.read_response;
      Bit#(TSub#(TSub#(`vaddr, TLog#(`btbsize)),`ignore)) bht_tag0 = truncate(bht_tag_state0);
      Bit#(3) state0 = truncateLSB(bht_tag_state0);

      // extract the target - address, tags, counter - value and prediction state from bank1
      let bimodal_target_addr1 = mem_btb1.read_response;
      let bht_tag_state1 = mem_btb_tag1.read_response;
      Bit#(TSub#(TSub#(`vaddr, TLog#(`btbsize)),`ignore)) bht_tag1 = truncate(bht_tag_state1);
      Bit#(3) state1 = truncateLSB(bht_tag_state1);
      `logLevel( bimodal, 1, $format("Bimodal : va:%h bht0:%h state0:%b bht1:%h state1:%b",
                                      request.pc, bht_tag0, state0, bht_tag1, state1))

    `ifdef ras
      // extract tag from the request PC for comparison
      Bit#(TSub#(TSub#(`vaddr, TLog#(`rassets)),`ignore)) ras_tag_cmp = truncateLSB(request.pc);

      // extract the target - address, tags, counter - value and prediction state from bank0
      let ras_tag_valid0 = mem_ras_tag0.read_response;
      Bit#(TSub#(TSub#(`vaddr, TLog#(`rassets)),`ignore)) ras_tag0 = truncate(ras_tag_valid0);
      Bit#(1) ras_valid0 = truncateLSB(ras_tag_valid0);

      // extract the target - address, tags, counter - value and prediction state from bank1
      let ras_tag_valid1 = mem_ras_tag1.read_response;
      Bit#(TSub#(TSub#(`vaddr, TLog#(`rassets)),`ignore)) ras_tag1 = truncate(ras_tag_valid1);
      Bit#(1) ras_valid1 = truncateLSB(ras_tag_valid1);
      let ras_target_address = ras_stack.top;
    `endif

      Bit#(`vaddr) target_address = bimodal_target_addr0;

      // ------------------------------ bimodal look-up start ----------------------------------- //
      // When compressed is disabled we need to check which bank should the prediction be taken
      // from. This is done by checking the LSB bit of the full - index (a.k.a the va[ignore]). This
      // is required because 2 PCs which have the same bank_index (but point to different banks) 
      // and have the same tags as well (i.e. they vary only in the ignore bit of the va. Eg 0x0 and
      // 0x4) can both be valid entries in the respective banks. This will lead to bank1 overwriting
      // the prediction output of bank0 which is wrong.
      if (btb_tag_cmp == bht_tag0 && state0[2] == 1 &&
               `ifdef  compressed !request.discard `else request.pc[`ignore] == 0 `endif ) begin

      `ifdef compressed
        prediction0 = state0[1 : 0];
        prediction = state0[1 : 0];
      `else
        prediction = state0[1 : 0];
      `endif
        `logLevel( bimodal, 1, $format("Bimodal : btb_tag_cmp:%h, tag0:%h,",btb_tag_cmp, bht_tag0))
        `logLevel( bimodal, 1, $format("Bimodal : BTB0 hit"))
        hit[0] = 1;
      end
      if (btb_tag_cmp == bht_tag1 && state1[2] == 1
               `ifndef compressed && request.pc[`ignore] == 1 `endif ) begin
      `ifdef compressed
        prediction1 = state1[1 : 0];
        if(hit[0] == 0)begin
          target_address = bimodal_target_addr1;
          prediction = state1[1 : 0];
        end
        hit[0] = 1;
      `else
        prediction = state1[1 : 0];
        target_address = bimodal_target_addr1;
        hit[1] = 1;
      `endif
        `logLevel( bimodal, 1, $format("Bimodal : BTB0 hit"))
      end
      // ----------------------------------- bimod look up end --------------------------------- //

      // ------------------------------------ RAS look-up start -------------------------------- //
    `ifdef ras
      if( ras_tag_cmp == ras_tag0 && ras_valid0 == 1 && !ras_stack.empty && 
                    `ifdef compressed !request.discard `else request.pc[`ignore] == 0 `endif )begin
      `ifdef compressed
        prediction0 = 3;
        prediction = 3;
      `else
        prediction = 3;
      `endif
        target_address = ras_stack.top;
        ras_stack.pop;
        `logLevel( bimodal, 1, $format("Bimodal : RAS0 hit. Target:%h", target_address))
        hit[2] = 1;
      end
      else if( ras_tag_cmp == ras_tag1 && ras_valid1 == 1 && !ras_stack.empty
                `ifndef compressed && request.pc[`ignore]==1 `endif )begin
      `ifdef compressed
        prediction1 = 3;
        if(hit2[2] == 0) begin
          prediction = 3;
          target_address = ras_target_address1;
        end
        hit[2] = 1;
      `else
        prediction = 3;
        target_address = ras_stack.top;
        hit[2] = 1;
      `endif
        `logLevel( bimodal, 1, $format("Bimodal : RAS1 hit Target:%h", target_address))
        ras_stack.pop;
      end
    `endif
  `ifndef compressed
    `ifdef ASSERT
      dynamicAssert(countOnes(hit) <= 1, "Multiple hits in BPU");
    `endif
  `endif
      let resp = PredictionResponse{ va       : request.pc
                                  `ifdef compressed
                                     ,discard     : request.discard
                                     ,prediction0 : prediction0
                                     ,prediction1 : prediction1
                                  `else
                                     ,prediction : prediction
                                  `endif } ;
      `logLevel( bimodal, 0, $format("Bimodal : enquing Response:",fshow(resp)))
      rg_prediction_pc[0] <= PredictionToStage0{prediction : prediction,
                                              target_pc : target_address};
      ff_prediction_resp.enq(resp);
    endrule

    // MethodName : prediction_req
    // Explicit Conditions : rg_init == False
    // Implicit Conditions : None
    // Description : This rule will latch the index of the PC to be predicted.
    // We first derive the full_index : the index assuming a non - banked array of `btbsize.
    // from the full index we then derive the index for each bank (bank_index) by ignoring the 
    // LSB of the full_index. 
		method Action prediction_req(PredictionRequest req)if(!rg_init);
      // first find the full index.
      Bit#(TLog#(`btbsize)) btb_full_index = truncate(req.pc>>`ignore);
      Bit#(TLog#(`rassets)) ras_full_index = truncate(req.pc>>`ignore);

      // find the bank_index.
      Bit#(TLog#(TDiv#(`btbsize, 2))) btb_bank_index = truncateLSB(btb_full_index); 
      Bit#(TLog#(TDiv#(`rassets, 2))) ras_bank_index = truncateLSB(ras_full_index); 

      mem_btb0.read(btb_bank_index);
      mem_btb1.read(btb_bank_index);
      mem_btb_tag0.read(btb_bank_index);
      mem_btb_tag1.read(btb_bank_index);
    `ifdef ras
      mem_ras_tag0.read(ras_bank_index);
      mem_ras_tag1.read(ras_bank_index);
    `endif
      if(req.fence) begin
        rg_init <= True;
        `logLevel( bimodal, 0, $format("Bimodal : Fence Recieved"))
      end
      else begin
        ff_pred_request.enq(req);
        `logLevel( bimodal, 0, $format("Bimodal : Prediction request for PC:%h btb_bank_index:%d",
                                        req.pc, btb_bank_index 
                           `ifdef ras  ," ras_bank_index:%d", ras_bank_index `endif ))
      end
		endmethod

    // MethodName : prediction_resp
    // Explicit Conditions : None
    // Implicit Conditions : None
    // Description : This rule read the response from the rams, check if the next PC is either PC + 4
    // or redirected to a new target address. The redirect address is directly taken from the ram.
    // If there is not hit in the BTB the prediction value of 0 is sent indicating that the next PC
    // is PC + 4 which needs to happen outside this module
		interface prediction_response = toGet(ff_prediction_resp);

    // MethodName : training
    // Explicit Conditions : rg_init == False
    // Implicit Conditions : None 
    // Description : This method will update the BTB and BHT with the new training packet from the
    // execute stage. 
    // We first derive the full_index : the index assuming a non - banked array of `btbsize.
    // from the full index we then derive the index for each bank (bank_index) by ignoring the 
    // LSB of the full_index. The LSB bit is used to identify which bank will be used for training.
		method Action train_bpu (Training_data td)if(!rg_init);
      let {pc, branch_address, state} = td;

      // first find the full index.
      Bit#(TLog#(`btbsize)) full_index = truncate(pc>>`ignore);

      // find the bank_index.
      Bit#(TLog#(TDiv#(`btbsize, 2))) bank_index = truncateLSB(full_index); 
      
      // find the tag to be stored.=vaddr - Log(btbsize) - ignorebits
      Bit#(TSub#(TSub#(`vaddr, TLog#(`btbsize)),`ignore)) tag = truncateLSB(pc);
      if (truncate(full_index) == 1'b0)begin
        mem_btb0.write    (1, bank_index, branch_address);
        mem_btb_tag0.write(1, bank_index, {1'b1, state, tag});
        `logLevel( bimodal, 0, $format("Bimodal : Training BTB0: ",fshow(td)))
        `logLevel( bimodal, 0, $format("Bimodal : Training BTB0 : bank_index:%d tag:%h state:%b",
                                        bank_index, tag, state))
      end
      else begin
        mem_btb1.write    (1, bank_index, branch_address);
        mem_btb_tag1.write(1, bank_index, {1'b1, state, tag});
        `logLevel( bimodal, 0, $format("Bimodal : Training BTB1: ",fshow(td)))
        `logLevel( bimodal, 0, $format("Bimodal : Training BTB1 : bank_index:%d tag:%h state:%b", 
                                       bank_index, tag, state))
      end
		endmethod

    // MethodName : prediction_pc
    // Explicit Conditions : None
    // Implicit Conditions : None 
    // Description : This method sends the latest prediction to stage0 for generating next pc
    method predicted_pc = rg_prediction_pc[1];

  `ifdef ras
    // MethodName : train_ras
    // Explicit Conditions : rg_init == False
    // Implicit Conditions : None 
    // Description : This method will update the RAS tag and state entries to indicate a pop
    method Action train_ras(Bit#(`vaddr) pc)if(!rg_init);
      $display("Training RAS");
      // first find the full index.
      Bit#(TLog#(`rassets)) full_index = truncate(pc>>`ignore);

      // find the bank_index.
      Bit#(TLog#(TDiv#(`rassets, 2))) bank_index = truncateLSB(full_index); 
      
      // find the tag to be stored.=vaddr - Log(rassets) - ignorebits
      Bit#(TSub#(TSub#(`vaddr, TLog#(`rassets)), `ignore)) tag = truncateLSB(pc);

      if(truncate(full_index)==1'b0)begin
        mem_ras_tag0.write(1, bank_index, {1'b1, tag});
        `logLevel( bimodal, 0, $format("Bimodal : Training RAS0 for ",fshow(pc)))
        `logLevel( bimodal, 0, $format("Bimodal : Training RAS0 : bank_index:%d tag:%h", 
                                        bank_index, tag))
      end
      else begin
        mem_ras_tag1.write(1, bank_index, {1'b1, tag});
        `logLevel( bimodal, 0, $format("Bimodal : Training RAS1 for ",fshow(pc)))
        `logLevel( bimodal, 0, $format("Bimodal : Training RAS1 : bank_index:%d tag:%h", 
                                        bank_index, tag))
      end
    endmethod

    // MethodName : ras_push
    // Explicit Conditions : None
    // Implicit Conditions : None 
    // Description : This method will push a return address on the RAS stack
    method Action ras_push(Bit#(`vaddr) pc);
      `logLevel( bimodal, 0, $format("Bimodal : Pushing to RAS:%h ",pc))
      ras_stack.push(pc);
    endmethod
  `endif
	endmodule
endpackage
