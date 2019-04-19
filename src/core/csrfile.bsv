/* 
Copyright (c) 2013, IIT Madras All rights reserved.

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
package csrfile;
  
  // project related imports
  import common_types::*;
  `include "common_params.bsv"
  `include "csr.defines"
  `include "Logger.bsv"
  import ConcatReg::*;
  import BUtils::*;
  import Vector::*;
  import ConfigReg::*;
  interface Ifc_csrfile;
    method ActionValue#(Bit#(XLEN)) read_csr (Bit#(12) addr);
    method Action write_csr(Bit#(12) addr,  Bit#(XLEN) word, Bit#(2) lpc);
    method ActionValue#(Bit#(`vaddr)) upd_on_ret `ifdef non_m_traps (Privilege_mode prv) `endif ;
    method ActionValue#(Bit#(`vaddr)) upd_on_trap(Bit#(`causesize) cause, Bit#(`vaddr) pc, Bit#(`vaddr) tval);
    method Action incr_minstret;
  // ------------------------ csrs to other pipeline stages ---------------------------------//
    method CSRtoDecode csrs_to_decode;
	`ifdef supervisor
		method Bit#(XLEN) csr_satp;
	`endif
  `ifdef spfpu
    method Action update_fflags(Bit#(5) flags);
  `endif
    method Bit#(3) mv_cacheenable;
  //returns arithmetic exception enabled/disabled
  `ifdef arith_trap
    method Bit#(1) arith_excep;
  `endif
    method Bit#(1) csr_misa_c;
    method Bit#(2) curr_priv;
    method Bit#(XLEN) csr_mstatus;
  //-------------------------- sideband connections -----------------------------------------//
	  method Action clint_msip(Bit#(1) intrpt);
		method Action clint_mtip(Bit#(1) intrpt);
		method Action clint_mtime(Bit#(64) c_mtime);
	  method Action set_external_interrupt(Bit#(1) ex_i);
  // ---------------------------------------------------------------------------------------//
  `ifdef pmp
    method Vector#(`PMPSIZE, Bit#(8)) pmp_cfg;
    method Vector#(`PMPSIZE, Bit#(`paddr )) pmp_addr;
  `endif
  `ifdef debug
    method Action debug_halt_request(Bit#(1) ip);
    method Action debug_resume_request(Bit#(1) ip);
    method Bit#(1) core_is_halted;
    method Bit#(1) step_is_set;
    method Bit#(1) step_ie;
    method Bit#(1) core_debugenable;
  `endif
  endinterface

  function Reg#(Bit#(a)) extInterruptReg(Reg#(Bit#(a)) r1, Reg#(Bit#(a)) r2);
    return (interface Reg;
      method Bit#(a) _read = r1 | r2;
      method Action _write(Bit#(a) x); 
        r1._write(x);
			endmethod
    endinterface);
  endfunction
                                                                                                      
  function Reg#(t) writeSideEffect(Reg#(t) r, Action a);                                            
    return (interface Reg;                                                                          
            method t _read = r._read;                                                               
            method Action _write(t x);                                                              
                r._write(x);                                                                        
                a;                                                                                  
            endmethod                                                                               
        endinterface);                                                                              
  endfunction
  
  function Reg#(t) readOnlyReg(t r);
    return (interface Reg;
       method t _read = r;
       method Action _write(t x) = noAction;
    endinterface);
  endfunction

  (*synthesize*)
  (*mutually_exclusive="upd_on_ret, write_csr"*)
  (*mutually_exclusive="upd_on_trap, write_csr"*)
  (*preempts="write_csr, increment_cycle_counter"*)
  (*preempts="write_csr, incr_minstret"*)
  module mkcsrfile(Ifc_csrfile);
    let maxIndex = valueOf(XLEN);
    let paddr = valueOf(`paddr);
    let vaddr = valueOf(`vaddr);

  
    /////////////////////////////// Machine level register /////////////////////////
    // Current Privilege Level
	  Reg#(Privilege_mode) rg_prv <- mkReg(Machine); // resets to machine mode
	  
	  Bit#(XLEN) csr_mvendorid  = 0;   // To be provided by JEDEC.
    Bit#(XLEN) csr_marchid    = 0; // To be provided by the RISC - V foundation.
    Bit#(XLEN) csr_mimpid     = 0; // Implementation ID set by SHAKTI.
    Bit#(XLEN) csr_mhartid    = 0;

	  //MISA fields
//    Reg#(Bit#(2)) rg_mxl <- mkReg(fromInteger(valueOf(TDiv#(XLEN, 32))));
    Bit#(2) mxl = fromInteger(valueOf(TDiv#(XLEN, 32)));
    `ifdef atomic
      Reg#(Bit#(1)) misa_a <- mkReg(1);
    `else
      Bit#(1) misa_a = 0;
    `endif
    `ifdef compressed
      Reg#(Bit#(1)) misa_c <- mkReg(1);
    `else
      Bit#(1) misa_c = 0;
    `endif
    `ifdef dpfpu
      Reg#(Bit#(1)) misa_d <- mkReg(1);
    `else
      Bit#(1) misa_d = 0;
    `endif
    `ifdef spfpu
      Reg#(Bit#(1)) misa_f <- mkReg(1);
    `else
      Bit#(1) misa_f = 0;
    `endif
    Reg#(Bit#(1)) misa_i <- mkReg(1);
    `ifdef muldiv
      Reg#(Bit#(1)) misa_m <- mkReg(1);
    `else
      Bit#(1) misa_m = 0;
    `endif
    `ifdef usertraps
      Reg#(Bit#(1)) misa_n <- mkReg(1);
    `else
      Bit#(1) misa_n = 0;
    `endif
    `ifdef supervisor
      Reg#(Bit#(1)) misa_s <- mkReg(1);
    `else
      `ifdef rtldump
        Bit#(1) misa_s = 1;
      `else
        Bit#(1) misa_s = 0;
      `endif
    `endif
    `ifdef user
      Reg#(Bit#(1)) misa_u <- mkReg(1);
    `else
      Bit#(1) misa_u = 0;
    `endif
    Bit#(26) misa = {5'd0, misa_u, 1'd0, misa_s, 4'd0, misa_n, misa_m, 3'd0, misa_i, 1'd0, 
          /*misa_i & misa_m & misa_a & misa_f & misa_d*/ 1'b0, misa_f, 1'd0, misa_d, misa_c, 1'd0, misa_a}; 
    //MTVEC trap vector fields
	  Reg#(Bit#(2)) rg_mode <- mkReg(0); //0 if pc to base or 1 if pc to base + 4xcause
	  Reg#(Bit#(TSub#(`vaddr, 2))) rg_mtvec <- mkReg(0);

    // mstatus fields
    `ifdef supervisor
      Reg#(Bit#(1)) tsr	  <-mkReg(0);// TODO add functionality 
      Reg#(Bit#(1)) tw	 	<-mkReg(0);// TODO add functionality 
      Reg#(Bit#(1)) tvm	  <-mkReg(0);// TODO add functionality 
      Reg#(Bit#(1)) mxr   <-mkReg(0);// 
      Reg#(Bit#(1)) sum   <-mkReg(0);// 
    `else
  	  Bit#(1) tsr	  = 0; // 0 if supervisor not supported
      Bit#(1) tw	 	= 0; // 0 if supervisor not supported
      Bit#(1) tvm	  = 0; // 0 if supervisor not supported
      Bit#(1) mxr   = 0; // 0 if supervisor not supported
      Bit#(1) sum   = 0; // 0 if supervisor not supported
    `endif
    Reg#(Bit#(1)) rg_mprv <- mkReg(0);
    Bit#(2) xs	 	= 0;
    // The FS field should only exist when floating point is enabled. But this is not the case
    // for spike. So currently we have it as a compulsory field for mstatus. 
    // 
    Reg#(Bit#(2)) fs	 	<-mkReg(0);
    Reg#(Bit#(1)) sd = readOnlyReg(pack((xs == 2'b11) || (fs == 2'b11)));
    Reg#(Bit#(2)) rg_mpp	<- mkReg(2'b0);
    Bit#(2) hpp	= 0;
    `ifdef supervisor
      Reg#(Bit#(1)) spp	<- mkReg(0);
    `else
      Bit#(1) spp	= 0;
    `endif

    Reg#(Bit#(1)) rg_mpie <- mkReg(0);
    Bit#(1) hpie = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) spie <- mkReg(0);
    `else
      Bit#(1) spie = 0;
    `endif
      	Reg#(Bit#(1)) rg_upie <- mkReg(0);

    Reg#(Bit#(1)) rg_mie	<- mkReg(`ifdef debug 1 `else 0 `endif ); // TODO  
    Bit#(1) hie = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) sie <- mkReg(0);
    `else
      Bit#(1) sie = 0;
    `endif
    Reg#(Bit#(1)) rg_uie <- mkReg(0);

	  // mie fields
    Reg#(Bit#(1)) rg_meie <- mkReg(0);
    Bit#(1) heie = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) seie <- mkReg(0);
    `else
      Bit#(1) seie = 0;
    `endif
    Reg#(Bit#(1)) rg_ueie <- mkReg(0);
    Reg#(Bit#(1)) rg_mtie <- mkReg(0);
    Bit#(1) htie = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) stie <- mkReg(0);
    `else
      Bit#(1) stie = 0;
    `endif
    Reg#(Bit#(1)) rg_utie <- mkReg(0);
    Reg#(Bit#(1)) rg_msie <- mkReg(0);
    Bit#(1) hsie = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) ssie <- mkReg(0);
    `else
      Bit#(1) ssie = 0;
    `endif

      Reg#(Bit#(1)) rg_usie <-  mkReg(0);

   
   `ifdef non_m_traps
      Reg#(Bit#(12)) rg_mideleg <- mkReg(0);
      Reg#(Bit#(10)) rg_medeleg_l10 <- mkReg(0); // cause 0 - 19
      Reg#(Bit#(2)) rg_medeleg_m2 <- mkReg(0);  // cause 12 - 13
      Reg#(Bit#(1)) rg_medeleg_u1 <- mkReg(0);  // cause 15
    `else
      Bit#(12) rg_mideleg = 0;
    `endif
    
	  // mip fields

    Reg#(Bit#(1)) rg_meip <- mkReg(0);
    Bit#(1) heip = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) soft_seip <- mkReg(0);
      Reg#(Bit#(1)) ext_seip <- mkReg(0);
      Reg#(Bit#(1)) seip = extInterruptReg(soft_seip, ext_seip); 
    `else
      Bit#(1) seip = 0; 
    `endif
    `ifdef usertraps
      Reg#(Bit#(1)) soft_ueip <- mkReg(0);
      Reg#(Bit#(1)) ext_ueip <- mkReg(0);
      Reg#(Bit#(1)) rg_ueip = extInterruptReg(soft_ueip, ext_ueip); 
      Reg#(Bit#(1)) rg_utip <- mkReg(0);
      Reg#(Bit#(1)) rg_usip <- mkReg(0);
    `else
      Bit#(1) rg_ueip = 0;
      Bit#(1) rg_utip = 0;
      Bit#(1) rg_usip = 0;
    `endif
    Reg#(Bit#(1)) rg_mtip <- mkReg(0);
    Bit#(1) htip = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) stip <- mkReg(0);
    `else
      Bit#(1) stip = 0;
    `endif
	  Reg#(Bit#(1)) rg_msip <- mkReg(0);
    Bit#(1) hsip = 0;
    `ifdef supervisor
      Reg#(Bit#(1)) ssip <- mkReg(0);
    `else
      Bit#(1) ssip = 0;
    `endif

    `ifdef RV64
	  	Reg#(Bit#(XLEN)) mcycle <- mkReg(0);
	  	Reg#(Bit#(XLEN)) minstret <- mkReg(0);
	  `else
	  	Reg#(Bit#(XLEN)) mcycle <- mkReg(0);
	  	Reg#(Bit#(XLEN)) minstret <- mkReg(0);
	  	Reg#(Bit#(XLEN)) mcycleh <- mkReg(0);
	  	Reg#(Bit#(XLEN)) minstreth <- mkReg(0);
	  `endif

	  // Machine Trap Handling
	  Reg#(Bit#(TSub#(`vaddr, 1))) rg_mepc  		<- mkReg(0);
	  Reg#(Bit#(XLEN)) rg_mtval  		<- mkReg(0);
	  Reg#(Bit#(XLEN)) rg_mscratch <- mkReg(0);
    
    Reg#(Bit#(1)) rg_minterrupt <- mkReg(0);
	  Reg#(Bit#(TSub#(`causesize,1))) rg_mcause   <- mkReg(0);
    
	  Reg#(Bit#(3)) rg_mcounteren <- mkReg(0);
	  Reg#(Bit#(64)) rg_clint_mtime <- mkReg(0);
	  //////////////////////////////////////////////////////////////////////////////////////////
	  //////////////////////////////// SUPERVISOR LEVEL CSRs ///////////////////////////////////
    `ifdef supervisor
      Bit#(2) sxl = fromInteger(valueOf(TDiv#(XLEN, 32))); 

      //STVEC trap vector fields
  	  Reg#(Bit#(2)) rg_smode <- mkReg(0); //0 if pc to base or 1 if pc to base + 4xcause
	    Reg#(Bit#(TSub#(`vaddr, 2))) rg_stvec <- mkReg(0);
  
      // SSCRATCH
      Reg#(Bit#(XLEN)) sscratch <- mkReg(0);

      // SCAUSE register
      Reg#(Bit#(1)) sinterrupt <- mkReg(0);
	    Reg#(Bit#(TSub#(`causesize,1))) scause   <- mkReg(0);

      // STVAL
	    Reg#(Bit#(`vaddr)) stval  		<- mkReg(0);
      // SEPC register
	    Reg#(Bit#(TSub#(`vaddr, 1))) sepc  		<- mkReg(0);
      Reg#(Bit#(`asidwidth)) satp_asid <- mkReg(0);
    `ifdef RV64
      Reg#(Bit#(44)) satp_ppn <- mkReg(0);
      Reg#(Bit#(4)) satp_mode <- mkReg(0);
    `else
      Reg#(Bit#(22)) satp_ppn <- mkReg(0);
      Reg#(Bit#(1)) satp_mode <- mkReg(0);
    `endif

      // SEDELEG and SIDELEG registers
      `ifdef usertraps
        Reg#(Bit#(14)) rg_sideleg <- mkReg(0);
        Reg#(Bit#(9)) rg_sedeleg_l9 <- mkReg(0); // cause 0 - 8
        Reg#(Bit#(2)) rg_sedeleg_m2 <- mkReg(0);  // cause 12 - 13
        Reg#(Bit#(1)) rg_sedeleg_u1 <- mkReg(0);  // cause 15
      `else
        Bit#(12) rg_sideleg = 0;
      `endif
    `else
      Bit#(2) sxl = fromInteger(valueOf(TDiv#(XLEN, 32))); 
    `endif
	  //////////////////////////////////////////////////////////////////////////////////////////
	  //////////////////////////////// USER LEVEL CSRs /////////////////////////////////////////
	  Reg#(Bit#(XLEN)) rg_uscratch <- mkReg(0);
    Bit#(2) uxl = fromInteger(valueOf(TDiv#(XLEN, 32))); 

    `ifdef usertraps
  	  Reg#(Bit#(TSub#(`vaddr, 1))) rg_uepc  		<- mkReg(0);
	    Reg#(Bit#(XLEN))rg_utval  		<- mkReg(0);
      Reg#(Bit#(1)) rg_uinterrupt <- mkReg(0);
  	  Reg#(Bit#(TSub#(`causesize,1))) rg_ucause   <- mkReg(0);
	    Reg#(Bit#(2)) rg_umode <- mkReg(0); //0 if pc to base or 1 if pc to base + 4xcause
  	  Reg#(Bit#(TSub#(`vaddr, 2))) rg_utvec <- mkReg(0);
    `endif
     Reg#(Bit#(5)) fflags <- mkReg(0);
     Reg#(Bit#(3)) frm <- mkReg(0);
	  //////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////// Physical Memory Protection /////////////////////////////////
    `ifdef pmp
      Vector#(`PMPSIZE, Reg#(Bit#(8))) v_pmp_cfg <- replicateM(mkReg(0));
      Vector#(`PMPSIZE, Reg#(Bit#(`paddr ))) v_pmp_addr <- replicateM(mkReg(0));
    `ifdef RV64
      Bit#(XLEN) csr_pmpcfg0 = 0;
      Bit#(XLEN) csr_pmpcfg2 = 0;
      for(Integer i = 0;i<`PMPSIZE ;i = i+1)begin
        if(i<8)
          csr_pmpcfg0[i * 8+7 : i*8] = v_pmp_cfg[i];
        else 
          csr_pmpcfg2[(i - 8) * 8+7 : (i - 8) * 8] = v_pmp_cfg[i];
      end

   `else RV32
      Bit#(XLEN) csr_pmpcfg0 = 0;
      Bit#(XLEN) csr_pmpcfg1 = 0;
      Bit#(XLEN) csr_pmpcfg2 = 0;
      Bit#(XLEN) csr_pmpcfg3 = 0;
      for(Integer i = 0;i<`PMPSIZE ;i = i+1)begin
        if(i<4)
          csr_pmpcfg0[i * 8+7 : i*8] = v_pmp_cfg[i];
        else if(i<8)
          csr_pmpcfg1[(i - 4) * 8+7 : (i - 4) * 8] = v_pmp_cfg[i];
        else if(i<12)
          csr_pmpcfg2[(i - 8) * 8+7 : (i - 8) * 8] = v_pmp_cfg[i];
        else 
          csr_pmpcfg2[(i - 12) * 8+7 : (i - 12) * 8] = v_pmp_cfg[i];
      end
    `endif
    `endif
	  //////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////// None Standard User RW CSRs /////////////////////////////////
    // Address : 'h800
  `ifdef icache
    // 0 - bit is cache enable for instruction cache
    Reg#(Bit#(1)) rg_ienable <- mkReg(fromInteger(valueOf(`icachereset)));
  `else
    Reg#(Bit#(1)) rg_ienable = readOnlyReg(0);
  `endif

  `ifdef dcache
    // 1 - bit is cache enable for data cache
    Reg#(Bit#(1)) rg_denable <- mkReg(fromInteger(valueOf(`dcachereset)));
  `else
    Reg#(Bit#(1)) rg_denable = readOnlyReg(0);
  `endif
  `ifdef bpu
    // 2 - bit is branch predictor enable
    Reg#(Bit#(1)) rg_bpuenable <- mkReg(fromInteger(valueOf(`bpureset)));
  `else
    Reg#(Bit#(1)) rg_bpuenable = readOnlyReg(0);
  `endif

  `ifdef arith_trap
    // 3 - bit if to enable traps on arithmetic ops
    Reg#(Bit#(1)) rg_arith_excep <-mkReg(0); 
  `else
    Reg#(Bit#(1)) rg_arith_excep = readOnlyReg(0);
  `endif

    Reg#(Bit#(4)) rg_customcontrol = concatReg4(rg_arith_excep, rg_bpuenable, rg_denable, rg_ienable); 
	  //////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////// Debug Module CSRs /////////////////////////////////////////
  `ifdef debug
    // DCSR - debug spec
    Reg#(Bit#(4)) rg_dcsr_xdebugver = readOnlyReg(4);                         // DCSR b31-28
    Reg#(Bit#(1)) rg_dcsr_ebreakm   <- mkReg(1);                              // DCSR b15
    Reg#(Bit#(1)) rg_dcsr_ebreaks   <- mkReg(0);                              // DCSR b13
    Reg#(Bit#(1)) rg_dcsr_ebreaku   <- mkReg(0);                              // DCSR b12
    Reg#(Bit#(1)) rg_dcsr_stepie    <- mkReg(0);                              // DCSR b11
    Reg#(Bit#(1)) rg_dcsr_stopcount <- mkReg(0);                              // DCSR b10
    Reg#(Bit#(1)) rg_dcsr_stoptime  <- mkReg(0);                              // DCSR b9
    Reg#(Bit#(3)) rg_dcsr_cause     <- mkReg(0);                              // DCSR b8-6
    Reg#(Bit#(1)) rg_dcsr_mprven    <- mkReg(0);                              // DCSR b4
    Reg#(Bit#(1)) rg_dcsr_nmip      <- mkReg(0);                              // DCSR b3
    Reg#(Bit#(1)) rg_dcsr_step      <- mkReg(0);                              // DCSR b2
    Reg#(Bit#(2)) rg_dcsr_prv       <- mkReg(3);                              // DCSR b1-0
    Reg#(Bit#(32)) rg_csr_dcsr =  concatReg15(rg_dcsr_xdebugver,readOnlyReg(12'd0),rg_dcsr_ebreakm,
    readOnlyReg(1'd0),rg_dcsr_ebreaks,rg_dcsr_ebreaku,rg_dcsr_stepie,rg_dcsr_stopcount,
    rg_dcsr_stoptime,readOnlyReg(rg_dcsr_cause),readOnlyReg(1'd0),rg_dcsr_mprven,  readOnlyReg(rg_dcsr_nmip),rg_dcsr_step,rg_dcsr_prv);

    // DPC - debug spec
	  Reg#(Bit#(TSub#(`vaddr, 1))) rg_csr_dpc  		<- mkReg(0);

    // DSCRATCH - debug spec
    Reg#(Bit#(XLEN))  rg_csr_dscratch     <- mkReg(0);
    // Shakti Debug DtVec - a machine mode accesabvle csr register. This will define where the
    // self-loop is 
    Reg#(Bit#(TSub#(`vaddr, 1))) rg_csr_dtvec <- mkReg(0); // Place debug loop at zero for starters
    Reg#(Bit#(1)) rg_csr_denable <- mkReg(1);

    // Part of shakti specific debug registers for control flow
    Reg#(Bit#(1))     rg_core_halted  <- mkConfigReg(0);     // using configreg to resolve conflicts
    Reg#(Bit#(1))     rg_halt_int     <- mkReg(0);
    Reg#(Bit#(1))     rg_resume_int   <- mkReg(0);
    Reg#(Bit#(1))     rg_halt_ie      = readOnlyReg(1);    
    Reg#(Bit#(1))     rg_resume_ie    = readOnlyReg(1);

  `else
    Reg#(Bit#(1)) rg_halt_ie    =  readOnlyReg(0);
    Reg#(Bit#(1)) rg_halt_int   =  readOnlyReg(0);
    Reg#(Bit#(1)) rg_resume_int =  readOnlyReg(0);
    Reg#(Bit#(1)) rg_resume_ie  =  readOnlyReg(0);
  `endif
    
	  //////////////////////////////////////////////////////////////////////////////////////////
    let csr_mip= { `ifdef debug rg_resume_int&rg_core_halted, rg_halt_int&~rg_core_halted, `endif 
                   rg_meip, heip, misa_s & seip, misa_n & rg_ueip, rg_mtip, htip, misa_s & stip, 
                   misa_n & rg_utip, misa_s & rg_msip, hsip, misa_s & ssip, misa_n & rg_usip};
    Bit#(12) csr_mie= {rg_meie, heie, seie, rg_ueie, rg_mtie, htie, stie, rg_utie, rg_msie,
                          hsie, ssie, rg_usie};
  `ifdef supervisor
    Bit#(12) csr_sip = {'d0, misa_s & seip, misa_n & rg_ueip, 2'd0, stip & misa_s, misa_n & rg_utip, 
                                                                2'd0, misa_s & ssip, misa_n & rg_usip};
    Bit#(12) csr_sie = {'d0, seie, misa_n & rg_ueie, 2'd0, stie, misa_n & rg_utie, 2'd0, ssie,
                                                                                  misa_n & rg_usie};
  `endif
  `ifdef usertraps
    Bit#(12) csr_uip = {'d0, misa_n & rg_ueip, 3'd0, misa_n & rg_utip, 3'd0, misa_n & rg_usip};
    Bit#(12) csr_uie = {'d0, misa_n & rg_ueie, 3'd0, misa_n & rg_utie, 3'd0, misa_n & rg_usie};
  `endif
    rule increment_cycle_counter;
	  	`ifdef RV64
      	mcycle <= mcycle + 1;
	  	`else
	  		Bit#(64) new_cycle={mcycleh, mcycle};
	  		new_cycle = new_cycle + 1;
	  		mcycle <= new_cycle[31 : 0];
	  		mcycleh <= new_cycle[63 : 32];
	  	`endif
    endrule

    method ActionValue#(Bit#(XLEN)) read_csr (Bit#(12) addr);
        `logLevel( csr, 0, $format("CSRFILE : Read Operation : Addr:%h",addr))
        Bit#(XLEN) data = 0;
        if (addr == `MVENDORID ) data = csr_mvendorid;
        if (addr == `MARCHID ) data = csr_marchid;
        if (addr == `MIMPID ) data = csr_mimpid;
        if (addr == `MHARTID ) data = csr_mhartid;
        if (addr == `MISA ) begin 
          data[25 : 0]= {5'd0, misa_u, 1'd0, misa_s, 4'd0, misa_n, misa_m, 3'd0, misa_i, 2'd0, 
          /*misa_i & misa_m & misa_a & misa_f & misa_d,*/ misa_f, 1'd0, misa_d, misa_c, 1'd0, misa_a}; 
          `ifdef RV64
            data[63 : 62] = mxl;
          `else
            data[31 : 30] = mxl;
          `endif
        end
        if (addr == `MTVEC ) data = signExtend({rg_mtvec, rg_mode}) ;
        if (addr == `MSTATUS )begin
          `ifdef RV64
              data= {sd, 27'd0, sxl, uxl, 9'd0, tsr, tw, tvm, mxr, sum, rg_mprv, xs, fs, rg_mpp,
                      hpp, spp, rg_mpie, hpie, spie, rg_upie, rg_mie, hie, sie, rg_uie};
          `else
              data= {'d0, sd, 8'd0, tsr, tw, tvm, mxr, sum, rg_mprv, xs, fs, rg_mpp, hpp, spp, rg_mpie,
                    hpie, spie, rg_upie, rg_mie, hie, sie, rg_uie};
          `endif
        end
	`ifdef non_m_traps 
          if (addr == `MIDELEG ) data= {'d0, rg_mideleg};
          if (addr == `MEDELEG ) data= {'d0, rg_medeleg_u1, 1'd0, rg_medeleg_m2, 2'd0, rg_medeleg_l10};
	`endif
        if (addr == `MIE ) data= {'d0, rg_meie, heie, seie, misa_n & rg_ueie, rg_mtie, htie, stie,
                                              misa_n & rg_utie, rg_msie, hsie, ssie, misa_n & rg_usie};
        if (addr == `MIP ) data= {'d0, rg_meip, heip, misa_s & seip, misa_n & rg_ueip, rg_mtip, htie,
          misa_s & stip, misa_n & rg_utip, rg_msip, hsip, misa_s & ssip, misa_n & rg_usip};
        if (addr == `MCYCLE ) data = mcycle;
        if (addr == `MINSTRET ) data = minstret;
        `ifndef RV64
          if (addr == `MCYCLEH ) data = mcycleh;
          if (addr == `MINSTRETH ) data = minstreth;
        `endif
        if (addr == `MEPC ) data = signExtend({rg_mepc, 1'b0});
        if (addr == `MTVAL ) data = signExtend(rg_mtval);//?
        if (addr == `MSCRATCH ) data = rg_mscratch;
        if (addr == `MCAUSE ) data= {rg_minterrupt, 'd0, rg_mcause};
        if (addr == `MCOUNTEREN ) data = zeroExtend(rg_mcounteren);
        if (addr == `MTIME ) data = truncate(rg_clint_mtime);
        `ifndef RV64
          if (addr == `MTIMEH ) data = truncateLSB(rg_clint_mtime);
        `endif
    `ifdef pmp
        if (addr == `PMPCFG0) data = csr_pmpcfg0;
        if (addr == `PMPCFG2) data = csr_pmpcfg2;
      `ifdef RV32
        if (addr == `PMPCFG1) data = csr_pmpcfg1;
        if (addr == `PMPCFG3) data = csr_pmpcfg3;
      `endif
        if (addr == `PMPADDR0 && `PMPSIZE >0) data = zeroExtend(v_pmp_addr[0]);
        if (addr == `PMPADDR1 && `PMPSIZE >1) data = zeroExtend(v_pmp_addr[1]);
        if (addr == `PMPADDR2 && `PMPSIZE >2) data = zeroExtend(v_pmp_addr[2]);
        if (addr == `PMPADDR3 && `PMPSIZE >3) data = zeroExtend(v_pmp_addr[3]);
        if (addr == `PMPADDR4 && `PMPSIZE >4) data = zeroExtend(v_pmp_addr[4]);
        if (addr == `PMPADDR5 && `PMPSIZE >5) data = zeroExtend(v_pmp_addr[5]);
        if (addr == `PMPADDR6 && `PMPSIZE >6) data = zeroExtend(v_pmp_addr[6]);
        if (addr == `PMPADDR7 && `PMPSIZE >7) data = zeroExtend(v_pmp_addr[7]);
        if (addr == `PMPADDR8 && `PMPSIZE >7) data = zeroExtend(v_pmp_addr[8]);
        if (addr == `PMPADDR9 && `PMPSIZE >8) data = zeroExtend(v_pmp_addr[9]);
        if (addr == `PMPADDR10 && `PMPSIZE >10) data = zeroExtend(v_pmp_addr[11]);
        if (addr == `PMPADDR11 && `PMPSIZE >11) data = zeroExtend(v_pmp_addr[12]);
        if (addr == `PMPADDR12 && `PMPSIZE >12) data = zeroExtend(v_pmp_addr[13]);
        if (addr == `PMPADDR13 && `PMPSIZE >13) data = zeroExtend(v_pmp_addr[14]);
        if (addr == `PMPADDR14 && `PMPSIZE >14) data = zeroExtend(v_pmp_addr[15]);
        if (addr == `PMPADDR15 && `PMPSIZE >15) data = zeroExtend(v_pmp_addr[16]);
    `endif
        // =============== Supervisor level CSRs ==========//
        `ifdef supervisor
          if (addr == `SSTATUS )
          `ifdef RV64
              data= {sd, 29'd0, uxl, 12'd0, mxr, sum, 1'd0, xs, fs, 2'd0,
                      2'd0, spp, 1'd0, 1'd0, spie, rg_upie, 1'd0, 1'd0, sie, rg_uie};
          `else
              data= {'d0, sd, 11'd0, mxr, sum, 1'd0, xs, fs, 2'd0, 2'd0, spp, rg_mpie,
                      1'd0, spie, rg_upie, 1'd0, 1'd0, sie, rg_uie};
          `endif
          if (addr == `STVEC ) begin data = signExtend({rg_stvec, rg_smode}); end
          if (addr == `SIP ) data = {'d0, misa_s & seip, misa_n & rg_ueip, 2'd0, stip & misa_s,
                                      misa_n & rg_utip, 2'd0, misa_s & ssip, misa_n & rg_usip};
          if (addr == `SIE ) data = {'d0, seie, misa_n & rg_ueie, 2'd0, stie, misa_n & rg_utie, 2'd0, ssie,
                                                                                      misa_n & rg_usie};
          if (addr == `SSCRATCH ) data = sscratch;
          if (addr == `SEPC ) data = signExtend({sepc, 1'b0});
          if (addr == `SCAUSE ) data= {sinterrupt, 'd0, scause};
          if (addr == `STVAL ) data = signExtend(stval);//?
          if (addr == `SATP ) data = {satp_mode,'d0, satp_asid, satp_ppn};
        `ifdef usertraps
          if (addr == `SIDELEG ) data= {'d0, rg_sideleg};
          if (addr == `SEDELEG ) data= {'d0, rg_sedeleg_u1, 1'd0, rg_sedeleg_m2, 3'd0, rg_sedeleg_l9};
        `endif
        `endif
        // =============== User level CSRs ================//
        `ifdef usertraps
          if (addr == `USTATUS )
          `ifdef RV64
              data= {sd, 29'd0, uxl, 12'd0, 2'd0, 1'd0, xs, fs, 2'd0,
                      2'd0, spp, 1'd0, 1'd0, 1'd0, rg_upie, 1'd0, 1'd0, 1'd0, rg_uie};
          `else
              data= {'d0, sd, 11'd0, 2'd0, 1'd0, xs, fs, 2'd0, 2'd0, 1'd0, rg_mpie,
                      1'd0, 1'd0, rg_upie, 1'd0, 1'd0, 1'd0, rg_uie};
          `endif
          if (addr == `UIE) data= {'d0, rg_meie, heie, seie, rg_mideleg[8] & rg_ueie, rg_mtie, htie, 
                         stie, rg_mideleg[4] & rg_utie, rg_msie, hsie, ssie, rg_mideleg[0] & rg_usie}; 
          if (addr == `UTVEC ) data= {'d0, rg_utvec, rg_umode};
          if (addr == `USCRATCH ) data = rg_uscratch;
          if (addr == `UEPC ) data = signExtend({rg_uepc, 1'b0});
          if (addr == `UTVAL ) data = signExtend(rg_utval);
          if (addr == `UCAUSE ) data= {rg_uinterrupt, 'd0, rg_ucause};
          if (addr == `UIP) data= {'d0, rg_meip, heip, misa_s & seip, rg_mideleg[8] & rg_ueip & misa_n, rg_mtip, htie, 
                         stie, rg_mideleg[4] & rg_utip & misa_n, rg_msip, hsip, misa_s & ssip,
                         rg_mideleg[0] & rg_usip & misa_n};
        `endif
        if (addr == `UCYCLE ) data = mcycle;
        if (addr == `UINSTRET ) data = minstret;
      `ifndef RV64
        if (addr == `UCYCLEH ) data = mcycleh;
        if (addr == `UINSTRETH ) data = minstreth;
      `endif
        if (addr == `UTIME ) data = truncate(rg_clint_mtime);
        if (addr == `FFLAGS ) data = zeroExtend(fflags);
        if (addr == `FRM ) data = zeroExtend(frm);
        if (addr == `FCSR ) data = zeroExtend({frm, fflags});
        if (addr == `CUSTOMCNTRL ) data = zeroExtend(rg_customcontrol);
      `ifdef debug
        if(addr == `DCSR) data = zeroExtend(rg_csr_dcsr);
        if(addr == `DPC ) data = signExtend({rg_csr_dpc,1'd0});
        if(addr == `DSCRATCH ) data = rg_csr_dscratch;
        if(addr == `DTVEC ) data = signExtend({rg_csr_dtvec,1'd0});
        if(addr == `DENABLE ) data = zeroExtend(rg_csr_denable);
      `endif
        `logLevel( csr, 0, $format("CSRFILE : Read Operation : Addr:%h Data:%h",addr,data))
        return data;
    endmethod

    method Action write_csr(Bit#(12) addr,  Bit#(XLEN) word, Bit#(2) lpc);
        `logLevel( csr, 0, $format("CSRFILE : Write Operation : Addr:%h, word:%h",addr, word))
      case(addr)
        `MISA : begin 
          `ifdef atomic misa_a <= word[0]; `endif
          `ifdef compressed if(word[2] == 1 || (word[2] == 0 && lpc == 0)) misa_c <= word[2]; `endif  
          `ifdef dpfpu misa_d <= word[3]; `endif 
          `ifdef spfpu misa_f <= word[5]; `endif
            misa_i <= word[8];
          `ifdef muldiv misa_m <= word[12]; `endif
          `ifdef usertraps misa_n <= word[13]; `endif
          `ifdef supervisor misa_s <= word[18]; `endif
          `ifdef user misa_u <= word[20]; `endif
        end
        `MTVEC : begin 
          rg_mtvec <= word[paddr - 1:2]; 
          if(word[1 : 0]<2)
            rg_mode <= word[1 : 0];
        end
        `MSTATUS : begin 
            rg_uie <= word[0];
            rg_upie <= word[4];
          rg_mie <= word[3];
          rg_mpie <= word[7];
          if( word[12 : 11] == 3 || (misa_s == 1 && word[12 : 11] == 1) || (misa_u == 1 && word[12 : 11] == 0))
            rg_mpp <= word[12 : 11];
          rg_mprv <= word[17];
          fs <= word[14 : 13];
          `ifdef supervisor
            sie <= word[1];
            spie <= word[5];
            spp <= word[8];
            sum <= word[18];
            mxr <= word[19];
            tvm <= word[20];
            tw <= word[21];
            tsr <= word[22];
          `endif
        end
        `ifdef non_m_traps
          `MIDELEG : begin
            rg_mideleg <= truncate(word);
          end
          `MEDELEG : begin
            rg_medeleg_u1 <= word[15];
            rg_medeleg_m2 <= word[13 : 12];
            rg_medeleg_l10 <= word[9 : 0];
          end
        `endif
        `MIE : begin
          rg_msie <= word[3];
          rg_mtie <= word[7];
          rg_meie <= word[11];
            rg_ueie <= word[8];
            rg_usie <= word[0];
            rg_utie <= word[4];
          `ifdef supervisor
            seie <= word[9];
            ssie <= word[1];
            stie <= word[5];
          `endif
        end
        `MIP : begin
          `ifdef usertraps
            if(misa_n == 1)begin
              rg_usip <= word[0];
              rg_utip <= word[4];
              soft_ueip <= word[8];
            end
          `endif
          `ifdef supervisor
          if(misa_s == 1)begin
            ssip <= word[1];
            stip <= word[5];
            soft_seip <= word[9];
          end
          `endif
        end
        `MCYCLE : begin
          mcycle <= word;
        end
        `MINSTRET : begin
          minstret <= word;
        end
        `ifndef RV64
          `MCYCLEH : mcycleh <= word;
          `MINSTRETH : minstreth <= word;
        `endif
        `MEPC : begin word = word>>1;rg_mepc <= truncate(word); end
        `MTVAL : rg_mtval <= truncate(word);
        `MSCRATCH : rg_mscratch <= word;
        `MCAUSE : begin
          rg_minterrupt <= word[maxIndex - 1];
          rg_mcause <= truncate(word);
        end
        `MCOUNTEREN : rg_mcounteren <= truncate(word);
        `ifdef usertraps
          `USTATUS : begin 
            rg_uie <= word[0];
            rg_upie <= word[4];
          end
        `endif
    `ifdef pmp
      `ifdef RV64
        `PMPCFG0 : for(Integer i = 0;i<`PMPSIZE && i<8 ; i = i+1)
                    if(v_pmp_cfg[i][7] == 0)
                      v_pmp_cfg[i] <= word[i * 8+7 : i*8];
        `PMPCFG2 : for(Integer i = 8;i<`PMPSIZE && i<16 ; i = i+1)
                    if(v_pmp_cfg[i][7] == 0)
                      v_pmp_cfg[i] <= word[(i - 8) * 8+7 : (i - 8) * 8];
      `else
        `PMPCFG0 : for(Integer i = 0;i<`PMPSIZE && i<4 ; i = i+1)
                    if(v_pmp_cfg[i][7] == 0)
                      v_pmp_cfg[i] <= word[i * 8+7 : i*8];
        `PMPCFG1 : for(Integer i = 4;i<`PMPSIZE && i<8 ; i = i+1)
                    if(v_pmp_cfg[i][7] == 0)
                      v_pmp_cfg[i] <= word[(i - 4) * 8+7 : (i - 4) * 8];
        `PMPCFG2 : for(Integer i = 8;i<`PMPSIZE && i<12 ; i = i+1)
                    if(v_pmp_cfg[i][7] == 0)
                      v_pmp_cfg[i] <= word[(i - 8) * 8+7 : (i - 8) * 8];
        `PMPCFG3 : for(Integer i = 12;i<`PMPSIZE && i<16 ; i = i+1)
                    if(v_pmp_cfg[i][7] == 0)
                      v_pmp_cfg[i] <= word[(i - 12) * 8+7 : (i - 12) * 8];
      `endif
        `PMPADDR0 : if(`PMPSIZE > 0 && v_pmp_cfg[0][7] == 0) v_pmp_addr[0] <= truncate(word);
        `PMPADDR1 : if(`PMPSIZE > 1 && v_pmp_cfg[1][7] == 0) v_pmp_addr[1] <= truncate(word);
        `PMPADDR2 : if(`PMPSIZE > 2 && v_pmp_cfg[2][7] == 0) v_pmp_addr[2] <= truncate(word);
        `PMPADDR3 : if(`PMPSIZE > 3 && v_pmp_cfg[3][7] == 0) v_pmp_addr[3] <= truncate(word);
        `PMPADDR4 : if(`PMPSIZE > 4 && v_pmp_cfg[4][7] == 0) v_pmp_addr[4] <= truncate(word);
        `PMPADDR5 : if(`PMPSIZE > 5 && v_pmp_cfg[5][7] == 0) v_pmp_addr[5] <= truncate(word);
        `PMPADDR6 : if(`PMPSIZE > 6 && v_pmp_cfg[6][7] == 0) v_pmp_addr[6] <= truncate(word);
        `PMPADDR7 : if(`PMPSIZE > 7 && v_pmp_cfg[7][7] == 0) v_pmp_addr[7] <= truncate(word);
        `PMPADDR8 : if(`PMPSIZE > 8 && v_pmp_cfg[8][7] == 0) v_pmp_addr[8] <= truncate(word);
        `PMPADDR9 : if(`PMPSIZE > 9 && v_pmp_cfg[9][7] == 0) v_pmp_addr[9] <= truncate(word);
        `PMPADDR10 : if(`PMPSIZE > 10 && v_pmp_cfg[10][7] == 0) v_pmp_addr[10] <= truncate(word);
        `PMPADDR11 : if(`PMPSIZE > 11 && v_pmp_cfg[11][7] == 0) v_pmp_addr[11] <= truncate(word);
        `PMPADDR12 : if(`PMPSIZE > 12 && v_pmp_cfg[12][7] == 0) v_pmp_addr[12] <= truncate(word);
        `PMPADDR13 : if(`PMPSIZE > 13 && v_pmp_cfg[13][7] == 0) v_pmp_addr[13] <= truncate(word);
        `PMPADDR14 : if(`PMPSIZE > 14 && v_pmp_cfg[14][7] == 0) v_pmp_addr[14] <= truncate(word);
        `PMPADDR15 : if(`PMPSIZE > 15 && v_pmp_cfg[15][7] == 0) v_pmp_addr[15] <= truncate(word);
    `endif
        `USCRATCH : rg_uscratch <= word;
        ////////////////////// Supervisor Level Registers /////////////////
        `ifdef supervisor
          `STVEC : begin 
            rg_stvec <= word[vaddr - 1:2]; 
            if(word[1 : 0]<2)
              rg_smode <= word[1 : 0];
          end
          `SSCRATCH : sscratch <= word;
          // make sure only valid values of satp - mode field cause a change in the satp reg
          `SATP : begin
            `ifdef RV64
              if(word[63 : 60] == 0 || word[63 : 60] == 8)begin // transparent or sv39
                satp_mode <= word[63 : 60];
                satp_ppn <= truncate(word);
                satp_asid <= truncate(word[59 : 44]);
              end
            `else
              satp_mode <= word[31];
              satp_ppn <= truncate(word);
              satp_asid <= truncate(word[30 : 22]);
            `endif

          end
          `SCAUSE : begin
            scause <= truncate(word);
            sinterrupt <= word[maxIndex - 1];
          end
          `STVAL : stval <= truncate(word);
          `SEPC : begin word = word>>1;sepc <= truncate(word); end
          `ifdef usertraps
            `SIDELEG : begin
                rg_sideleg <= truncate(word);
              end
            `SEDELEG : begin
              rg_sedeleg_u1 <= word[15];
              rg_sedeleg_m2 <= word[13 : 12];
              rg_sedeleg_l9 <= word[8 : 0];
              end
          `endif
          `SIP : begin
            if(misa_n == 1)begin
            `ifdef usertraps
              rg_usip <= word[0];
              soft_ueip <= word[8];
            `endif
            end
            `ifdef supervisor
            if(misa_s == 1)
              ssip <= word[1];
            `endif
          end
        `SIE : begin
          `ifdef usertraps
            rg_ueie <= word[8];
            rg_usie <= word[0];
            rg_utie <= word[4];
          `endif
          `ifdef supervisor
            seie <= word[9];
            ssie <= word[1];
            stie <= word[5];
          `endif
        end
        `SSTATUS : begin
          `ifdef usertraps
            rg_uie <= word[0];
            rg_upie <= word[4];
          `endif
          fs <= word[14 : 13];
          sie <= word[1];
          spie <= word[5];
          spp <= word[8];
          sum <= word[18];
          mxr <= word[19];
          tvm <= word[20];
          tw <= word[21];
          tsr <= word[22];
        end
        `endif
        ///////////////////////////////////////////////////////////////////
        `FFLAGS : begin fflags <= truncate(word); if(fflags != truncate(word)) fs <= 'b11; end
        `FRM : begin frm <= truncate(word); if(frm != truncate(word)) fs <= 'b11;end
        `FCSR : begin frm <= word[7 : 5]; fflags <= truncate(word); 
          if({frm, fflags}!=truncate(word)) 
            fs <= 2'b11;
          end

        `ifdef usertraps
          `UIE : begin
            rg_usie <= word[0];
            rg_utie <= word[4];
            rg_ueie <= word[8];
          end
          `UIP : begin
            if(misa_n == 1)begin
              rg_usip <= word[0];
              soft_ueip <= word[8];
            end
          end
          `UTVEC : begin 
            rg_utvec <= word[paddr - 1:2]; 
            if(word[1 : 0]<2)
              rg_umode <= word[1 : 0];
          end
          `UEPC : begin word = word>>1;rg_uepc <= truncate(word); end
          `UTVAL : rg_utval <= truncate(word);
          `UCAUSE : begin
            rg_uinterrupt <= word[maxIndex - 1];
            rg_ucause <= truncate(word);
          end
        `endif
        /////////////////////////////// Non standard User CSRs  ////////////////////
        `CUSTOMCNTRL:
          rg_customcontrol <= truncate(word);
      `ifdef debug
          `DCSR:  rg_csr_dcsr <=  truncate(word);
          `DPC:   rg_csr_dpc  <=  truncate(word>>1);
          `DSCRATCH: rg_csr_dscratch <= truncate(word);
          `DTVEC  : rg_csr_dtvec <= truncate(word>>1);
          `DENABLE : rg_csr_denable <= truncate(word);
      `endif
        default : noAction;
      endcase
    endmethod
    method csrs_to_decode = CSRtoDecode{
        prv : rg_prv,
        csr_mip : csr_mip,
        csr_mie : csr_mie,
      `ifdef non_m_traps csr_mideleg : rg_mideleg, `endif
        csr_misa : misa,
      `ifdef RV64
        csr_mstatus:{sd, 27'd0, sxl, uxl, 9'd0, tsr, tw, tvm, mxr, sum, rg_mprv, xs, fs, rg_mpp,
                      hpp, spp, rg_mpie, hpie, spie, rg_upie, rg_mie, hie, sie, rg_uie},
      `else
        csr_mstatus: {'d0, sd, 8'd0, tsr, tw, tvm, mxr, sum, rg_mprv, xs, fs, rg_mpp, hpp, spp, rg_mpie,
                    hpie, spie, rg_upie, rg_mie, hie, sie, rg_uie},
      `endif
      `ifdef supervisor
        csr_sip : csr_sip,
        csr_sie : csr_sie,
      `endif
      `ifdef usertraps
        `ifdef supervisor
          csr_sideleg : rg_sideleg,
        `endif
        csr_uie : csr_uie,
        csr_uip : csr_uip,
      `endif
        frm : frm
      `ifdef debug
        ,csr_dcsr : rg_csr_dcsr
      `endif };
  	method Action clint_msip(Bit#(1) intrpt);
  		rg_msip <= intrpt;
  	endmethod
  	method Action clint_mtip(Bit#(1) intrpt);
  		rg_mtip <= intrpt;
  	endmethod
  	method Action clint_mtime(Bit#(64) c_mtime);
  		rg_clint_mtime <= c_mtime;
  	endmethod
    
    method ActionValue#(Bit#(`vaddr)) upd_on_ret `ifdef non_m_traps (Privilege_mode prv) `endif ;
      `ifdef non_m_traps 
        `ifdef supervisor
          if(prv == Supervisor)begin
            spie <= 1;
            spp <= 0;
            rg_prv <= unpack({1'b0, spp});
	  		    sie <= spie;
            let lv_sepc = sepc;
            if(misa_c == 0)
              lv_sepc[0] = 0;
            return {lv_sepc, 1'b0};
          end else 
        `endif
        `ifdef usertraps
          if(prv == User)begin
            rg_upie <= 1;
            rg_prv <= User;
	    	  	rg_uie <= rg_upie;
            let lv_uepc = rg_uepc;
            if(misa_c == 0)
              lv_uepc[0] = 0;
            return {lv_uepc, 1'b0};
          end else
        `endif
      `endif
      begin
        rg_mpie <= 1;
        rg_mpp <= pack(User);
        rg_prv <= unpack(rg_mpp);
	  	  rg_mie <= rg_mpie;
        let lv_mepc = rg_mepc;
        if(misa_c == 0)
          lv_mepc[0] = 0;
        return {lv_mepc, 1'b0};
      end
    endmethod
    method ActionValue#(Bit#(`vaddr)) upd_on_trap(Bit#(`causesize) c, Bit#(`vaddr) pc, Bit#(`vaddr) tval);
      Bit#(`causesize) cause = c;
      Bit#(TSub#(`causesize,1)) code = truncate(cause);
      Bit#(1) trap_type = truncateLSB(cause);

      `ifdef non_m_traps
          Privilege_mode prv = Machine;
          Bit#(16) medeleg = {rg_medeleg_u1, 1'd0, rg_medeleg_m2, 2'd0, rg_medeleg_l10};
        `ifdef supervisor
          `ifdef usertraps
            Bit#(16) sedeleg = {rg_sedeleg_u1, 1'd0, rg_sedeleg_m2, 3'd0, rg_sedeleg_l9};
          `endif
        `endif
          Bool delegateM = (((rg_mideleg >> code) & 
                                1 & duplicate(trap_type)) == 1) ||  
                           (((medeleg >> code) & 
                                1 & duplicate(~trap_type)) == 1);
          `ifdef supervisor
            `ifdef usertraps
              Bool delegateS = (((rg_sideleg >> code) & 
                                    1 & duplicate(trap_type)) == 1) ||  
                               (((sedeleg >> code) & 
                                    1 & duplicate(~trap_type)) == 1);
            `endif
            if(delegateM && (pack(rg_prv) <= pack(Supervisor)) && (misa_s == 1))
              prv = Supervisor;
            `ifdef usertraps
              else if(delegateM && delegateS && rg_prv == User && misa_n == 1)
                prv = User;
            `endif
          `elsif usertraps
            if(delegateM && rg_prv == User && misa_n == 1)
              prv = User;
          `endif
          `logLevel( csr, 2, $format("CSRFILE : PC:%h C:%d Cause:%d misa_s:%b", pc, c,cause, misa_s))
          `ifdef non_m_traps
            `logLevel( csr, 2, $format("CSRFILE : medeleg:%b delegateM:%b",medeleg, delegateM))
          `endif
            `logLevel( csr, 2, $format("CSRFILE : rg_prv: ",fshow(rg_prv)," prv: ", fshow(prv)))
            `logLevel( csr, 2, $format("CSRFILE : rg_mtvec:%h rg_mode:%b", rg_mtvec, rg_mode))
          `ifdef supervisor
            `logLevel( csr, 2, $format("CSRFILE : rg_stvec:%h rg_smode:%b", rg_stvec, rg_smode))
          `endif

       // TODO: reduce the adders here to a single adder 
        `ifdef supervisor
          if(prv == Supervisor) begin
            stval <= signExtend(tval);
			      sepc <= truncateLSB(pc);
			      scause <= code;
            sinterrupt <= trap_type;
			      sie <= 0;
			      spie <= sie;
            spp <= pack(rg_prv)[0];
			      rg_prv <= Supervisor;
            if(rg_smode == 1 && trap_type == 1)
              return ({(rg_stvec + zeroExtend(code)), 2'b0}); // pc jumps to base + (4 * cause)
            else
              return {rg_stvec, 2'b0}; // pc jumps to base
          end else
        `endif
        `ifdef usertraps
          if(prv == User) begin
            rg_utval <= signExtend(tval);
			      rg_uepc <= truncateLSB(pc);
			      rg_ucause <= code;
            rg_uinterrupt <= trap_type;
			      rg_uie <= 0;
			      rg_upie <= rg_uie;
			      rg_prv <= User;
            if(rg_umode == 1 && trap_type == 1)
              return ({(rg_utvec + zeroExtend(code)), 2'b0}); // pc jumps to base + (4 * cause)
            else
              return {rg_utvec, 2'b0}; // pc jumps to base
          end else
        `endif
          begin
            Bit#(`vaddr) redirect; 
          `ifdef debug
            if(cause >= {1'b1,`HaltEbreak} && cause <= {1'b1, `HaltReset} ) begin
              `logLevel( csr, 3, $format("CSRFILE: Taking Halt interrupt. DCause:%d PC:%h", 
                                          cause[2:0], pc))
              rg_csr_dpc <= truncateLSB(pc);
              rg_dcsr_cause <= truncate(cause);
              rg_core_halted <= 1;
              rg_dcsr_prv <= pack(rg_prv);
              rg_prv <= Machine;
              redirect = {rg_csr_dtvec,1'd0};
            end
            else 
            if( cause == {1'b1,`Resume_int} ) begin
              `logLevel( csr, 3, $format("CSRFILE: Taking Resume interrupt. DPC:%h", 
                                          {rg_csr_dpc,1'd0}))
              redirect = {rg_csr_dpc,1'd0};
              rg_core_halted <= 0;
              rg_prv<= unpack(rg_dcsr_prv);
            end
            else 
          `endif
            begin
              rg_mtval <= signExtend(tval);
			        rg_mepc <= truncateLSB(pc);
			        rg_mcause <= code;
              rg_minterrupt <= trap_type;
			        rg_mie <= 0;
			        rg_mpp <= pack(rg_prv);
			        rg_mpie <= rg_mie;
			        rg_prv <= Machine;
              if(rg_mode == 1 && trap_type == 1)
                redirect = ({(rg_mtvec + zeroExtend(code)), 2'b0}); // pc jumps to base + (4 * cause)
              else
                redirect =  {rg_mtvec, 2'b0}; // pc jumps to base
            end
            return redirect;
          end
      `else
        begin
            Bit#(`vaddr) redirect ;
          `ifdef debug
            if(cause >= {1'b1,`HaltEbreak} && cause <= {1'b1, `HaltReset} ) begin
              `logLevel( csr, 3, $format("CSRFILE: Taking Halt interrupt. DCause:%d", cause[2:0]))
              rg_csr_dpc <= truncateLSB(pc);
              rg_dcsr_cause <= truncate(cause);
              rg_core_halted <= 1;
              rg_dcsr_prv <= pack(rg_prv);
              rg_prv <= Machine;
              redirect = {rg_csr_dtvec, 1'd0};
            end
            else 
            if( cause == {1'b1,`Resume_int} ) begin
              redirect = {rg_csr_dpc,1'd0};
              rg_core_halted <= 0;
              rg_prv<= unpack(rg_dcsr_prv);
            end
            else 
          `endif
            begin
              rg_mtval <= signExtend(tval);
			        rg_mepc <= truncateLSB(pc);
			        rg_mcause <= code;
              rg_minterrupt <= trap_type;
			        rg_mie <= 0;
			        rg_mpp <= pack(rg_prv);
			        rg_mpie <= rg_mie;
			        rg_prv <= Machine;
              if(rg_mode == 1 && trap_type == 1)
                redirect = ({(rg_mtvec + zeroExtend(code)), 2'b0}); // pc jumps to base + (4 * cause)
              else
                redirect =  {rg_mtvec, 2'b0}; // pc jumps to base
            end
            return redirect;
        end
      `endif
    endmethod
    method Action incr_minstret;
      `ifdef RV64
        minstret <= minstret + 1;
      `else
        Bit#(TMul#(2, XLEN)) instr ={minstreth, minstret};
        instr = instr + 1;
        minstreth <= truncateLSB(instr); 
        minstret <= truncate(instr);
      `endif
    endmethod
	  `ifdef supervisor
	    method csr_satp = {satp_mode,'d0, satp_asid, satp_ppn};
	  `endif
    `ifdef spfpu
      method Action update_fflags(Bit#(5) flags);
        if((flags|fflags) != fflags)begin
          fflags <= flags|fflags;
          fs <= 'b11;
        end
      endmethod
    `endif
	  method Action set_external_interrupt(Bit#(1) ex_i);
  // TODO. seip and ueip can be updated by the PLIC. This is creating schedule conflicts
	  	if(rg_prv == Machine) begin 
	  		rg_meip <= pack(ex_i);
	  	end
    `ifdef supervisor
  		else if(rg_prv == Supervisor) begin
	  		ext_seip <= pack(ex_i);
	  	end
    `endif
    `ifdef usertraps
  		else if(rg_prv == User) begin
	  		ext_ueip <= pack(ex_i);
	  	end
    `endif
	  endmethod
    method csr_misa_c = misa_c;
    method curr_priv = pack(rg_prv);
    method Bit#(XLEN) csr_mstatus;
      `ifdef RV64
        return {sd, 27'd0, sxl, uxl, 9'd0, tsr, tw, tvm, mxr, sum, rg_mprv, xs, fs, rg_mpp,
                  hpp, spp, rg_mpie, hpie, spie, rg_upie, rg_mie, hie, sie, rg_uie};

      `else
        return {'d0, sd, 8'd0, tsr, tw, tvm, mxr, sum, rg_mprv, xs, fs, rg_mpp, hpp, spp, rg_mpie,
                hpie, spie, rg_upie, rg_mie, hie, sie, rg_uie};
      `endif
    endmethod
    method mv_cacheenable = truncate(rg_customcontrol);
  `ifdef arith_trap
    method Bit#(1) arith_excep = rg_customcontrol[3];
  `endif
  `ifdef pmp
    method pmp_cfg = readVReg(v_pmp_cfg);
    method pmp_addr = readVReg(v_pmp_addr);
  `endif
  `ifdef debug
    method Action debug_halt_request(Bit#(1) ip);
      rg_halt_int <= ip;
    endmethod
    method Action debug_resume_request(Bit#(1) ip);
      rg_resume_int <= ip;
    endmethod
    method core_is_halted = rg_core_halted;
    method step_is_set = rg_dcsr_step;
    method step_ie = rg_dcsr_stepie;
    method core_debugenable = rg_csr_denable;
  `endif
  endmodule
endpackage
