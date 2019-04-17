/* 
Copyright (c) 2013, IIT Madras All rights reserved.

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
package SoC;
  // project related imports
	import Semi_FIFOF:: *;
	import AXI4_Types:: *;
	import AXI4_Fabric:: *;
	import AXI4_Lite_Types:: *;
	import AXI4_Lite_Fabric:: *;
  import Tilelink_lite_Types::*;
  import Tilelink_lite::*;
  import cclass:: * ;
  import common_types:: * ;
  import Clocks :: *;
  `include "common_params.bsv"
  `include "SoC.defines"

  // peripheral imports
  import bram::*;
  import bootrom:: *;
  import uart::*;
  import clint::*;
  import Tbsign_dump::*;
  import err_slave::*;
  // package imports
  import Connectable:: *;
  import GetPut:: *;
  import Vector::*;

`ifdef debug
  import debug_types::*;                                                                          
  import jtagdtm::*;                                                                              
  import riscvDebug013::*;                                                                        
  import debug_halt_loop::*;
`endif

  typedef 0 Sign_master_num;
  typedef (TAdd#(Sign_master_num, 1)) Mem_master_num;
  typedef (TAdd#(Mem_master_num, 1)) Fetch_master_num;
  typedef (TAdd#(Fetch_master_num, `ifdef cache_control 1 `else 0 `endif )) IO_master_num;
  typedef (TAdd#(IO_master_num, `ifdef debug 1 `else 0 `endif )) Debug_master_num;
  typedef (TAdd#(Debug_master_num, 1)) Num_Masters;
 
 `ifdef CORE_TLU
    function Tuple2 #(Bool, Bit#(TLog#(`Num_Slaves))) fn_slave_map (A_Opcode_lite cmd, 
                                                                                 Bit#(`paddr) addr);
      Bool slave_exist = True;
      Bit#(TLog#(`Num_Slaves)) slave_num = 0;
      if(addr >= `MemoryBase && addr<= `MemoryEnd)
        if(cmd==Get_data)
          slave_num = `Memory_slave_num;
        else
          slave_num = `Memory_wr_slave_num;
      else
      `ifdef BOOTROM
        if(addr>= `BootRomBase && addr<= `BootRomEnd)
          slave_num =  `BootRom_slave_num;
        else
      `endif
        slave_exist = False;
        
      return tuple2(slave_exist, slave_num);
    endfunction:fn_slave_map
 `else
    function Bit#(TLog#(`Num_Slaves)) fn_slave_map (Bit#(`paddr) addr);
      Bit#(TLog#(`Num_Slaves)) slave_num = 0;
      if(addr >= `MemoryBase && addr<= `MemoryEnd)
        slave_num = `Memory_slave_num;
      else if(addr>= `BootRomBase && addr<= `BootRomEnd)
        slave_num =  `BootRom_slave_num;
      else if(addr>= `UartBase && addr<= `UartEnd)
        slave_num = `Uart_slave_num;
      else if(addr>= `ClintBase && addr<= `ClintEnd)
        slave_num = `Clint_slave_num;
      else if(addr>= `SignBase && addr<= `SignEnd)
        slave_num = `Sign_slave_num;
    `ifdef debug
      else if(addr>= `DebugBase && addr<= `DebugEnd)
        slave_num = `Debug_slave_num;
    `endif
      else
        slave_num = `Err_slave_num;
        
      return slave_num;
    endfunction:fn_slave_map
  `endif

  interface Ifc_SoC;
    `ifdef rtldump
      interface Get#(DumpType) io_dump;
    `endif
    `ifdef EXTERNAL
      interface AXI4_Master_IFC#(`paddr, ELEN, USERSPACE) mem_master;
    `endif
    interface RS232 uart_io;
  `ifdef debug
      // ------------- JTAG IOs ----------------------//
    (*always_enabled,always_ready*)                                                               
    method Action wire_tms(Bit#(1)tms_in);                                                        

    (*always_enabled,always_ready*)                                                               
    method Action wire_tdi(Bit#(1)tdi_in);                                                        

    (*always_enabled,always_ready*)                                                               
    method Bit#(1)wire_tdo;                                                                       
      // ---------------------------------------------//
  `endif
  endinterface

`ifdef CORE_AXI4
  (*synthesize*)
  module mkSoC#(Clock tck_clk, Reset trst)(Ifc_SoC);
    let curr_clk<-exposeCurrentClock;
    let curr_reset<-exposeCurrentReset;
    Ifc_cclass_axi4 cclass <- mkcclass_axi4();
    Ifc_Tbsign_dump signature<- mkTbsign_dump();
    AXI4_Fabric_IFC #(Num_Masters, `Num_Slaves, `paddr, ELEN, USERSPACE) 
                                                    fabric <- mkAXI4_Fabric(fn_slave_map);
 		Ifc_bram_axi4#(`paddr, ELEN, USERSPACE, `Addr_space) main_memory <- mkbram_axi4(`MemoryBase, 
                                                "code.mem.MSB", "code.mem.LSB", "MainMEM");
  `ifdef debug
    Ifc_debug_halt_loop#(`paddr, ELEN, USERSPACE) debug_memory <- mkdebug_halt_loop;
  `endif
		Ifc_bootrom_axi4#(`paddr, ELEN, USERSPACE) bootrom <-mkbootrom_axi4(`BootRomBase);
	  Ifc_uart_axi4#(`paddr,ELEN,0, 16) uart <- mkuart_axi4(curr_clk,curr_reset, 5);
    Ifc_clint_axi4#(`paddr, ELEN, 0, 1, 16) clint <- mkclint_axi4();
    Ifc_err_slave#(`paddr,ELEN,0) err_slave <- mkerr_slave;

    // -------------------------------- JTAG + Debugger Setup ---------------------------------- //
`ifdef debug
    // null crossing registers to transfer input signals from current_domain to tck domain
    CrossingReg#(Bit#(1)) tdi<-mkNullCrossingReg(tck_clk,0);                                        
    CrossingReg#(Bit#(1)) tms<-mkNullCrossingReg(tck_clk,0);                                        
    // null crossing registers to transfer signals from tck to curr_clock domain.
    CrossingReg#(Bit#(1)) tdo<-mkNullCrossingReg(curr_clk,0,clocked_by tck_clk, reset_by trst);     
                                                                                                    
    Ifc_jtagdtm jtag_tap <- mkjtagdtm(clocked_by tck_clk, reset_by trst);                           
    Ifc_riscvDebug013 debug_module <- mkriscvDebug013();                                           

    // synFIFOs to transact data between JTAG and debug module                                                                                                    
    SyncFIFOIfc#(Bit#(41)) sync_request_to_dm <-mkSyncFIFOToCC(1,tck_clk,trst);                     
    SyncFIFOIfc#(Bit#(34)) sync_response_from_dm <-mkSyncFIFOFromCC(1,tck_clk);                     
                           
             // ----------- Connect JTAG IOs through null-crossing registers ------ //
    rule assign_jtag_inputs;                                                                                
      jtag_tap.tms_i(tms.crossed);                                                                  
      jtag_tap.tdi_i(tdi.crossed);                                                                  
      jtag_tap.bs_chain_i(0);                                                                       
      jtag_tap.debug_tdi_i(0);                                                                      
    endrule                                                                                         
                                                                                                    
    rule assign_jtag_output;                                                                                 
      tdo <= jtag_tap.tdo(); //  Launched by a register clocked by inverted tck                     
    endrule                                                                                        
            // ------------------------------------------------------------------- //

    // capture jtag tap request into a syncfifo first.                                                                                                                  
    rule connect_tap_request_to_syncfifo;                                                           
      let x<-jtag_tap.request_to_dm;                                                                
      sync_request_to_dm.enq(zeroExtend(x));          

    // send captured synced jtag tap request to the debug module
    endrule                                                                                         
    rule read_synced_request_to_dm;                                                                 
      sync_request_to_dm.deq;                                                                       
      debug_module.dtm.putCommand.put(sync_request_to_dm.first);                                    
    endrule                                                                                         

    // collect debug response into a syncfifo
    rule connect_debug_response_to_syncfifo;                                                        
      let x <- debug_module.dtm.getResponse.get;                                                    
      sync_response_from_dm.enq(x);          
    endrule                                  

    // send synced debug response back to the JTAG
    rule read_synced_response_from_dm;                                                              
      sync_response_from_dm.deq;                                                                    
      jtag_tap.response_from_dm(sync_response_from_dm.first);                                       
    endrule                                                                                         
                                                                                                    
    mkConnection (cclass.debug_server ,debug_module.hart);
  `endif
      
    // ------------------------------------------------------------------------------------------//
  `ifdef debug
    mkConnection (debug_module.debug_master,fabric.v_from_masters[Debug_master_num]);
  `endif
   	mkConnection(cclass.master_d,	fabric.v_from_masters[valueOf(Mem_master_num)]);
   	mkConnection(cclass.master_i, fabric.v_from_masters[valueOf(Fetch_master_num)]);
  `ifdef cache_control
   	mkConnection(cclass.master_io, fabric.v_from_masters[valueOf(IO_master_num)]);
  `endif
   	mkConnection(signature.master, fabric.v_from_masters[valueOf(Sign_master_num) ]);

  	mkConnection(fabric.v_to_slaves[`Memory_slave_num ],main_memory.slave);
		mkConnection (fabric.v_to_slaves [`BootRom_slave_num ],bootrom.slave);
 	  mkConnection (fabric.v_to_slaves [`Uart_slave_num ],uart.slave);
  	mkConnection (fabric.v_to_slaves [`Clint_slave_num ],clint.slave);
    mkConnection (fabric.v_to_slaves [`Sign_slave_num ] , signature.slave);
    mkConnection (fabric.v_to_slaves [`Err_slave_num ] , err_slave.slave);
  `ifdef debug
    mkConnection (fabric.v_to_slaves [`Debug_slave_num ] , debug_memory.slave);
  `endif

    // sideband connection
    mkConnection(cclass.sb_clint_msip,clint.sb_clint_msip);
    mkConnection(cclass.sb_clint_mtip,clint.sb_clint_mtip);
    mkConnection(cclass.sb_clint_mtime,clint.sb_clint_mtime);

    `ifdef rtldump
      interface io_dump= cclass.io_dump;
    `endif
    interface uart_io=uart.io;

      // ------------- JTAG IOs ----------------------//
  `ifdef debug
    method Action wire_tms(Bit#(1)tms_in);                                                        
      tms <= tms_in;                                                                              
    endmethod                                                                                     
    method Action wire_tdi(Bit#(1)tdi_in);                                                        
      tdi <= tdi_in;                                                                              
    endmethod                                                                                     
    method Bit#(1)wire_tdo;                                                                       
      return tdo.crossed();                                                                       
    endmethod
  `endif
      // -------------------------------------------- //
  endmodule: mkSoC
`endif
`ifdef CORE_AXI4Lite
  (*synthesize*)
  module mkSoC(Ifc_SoC);
    Ifc_cclass_axi4lite cclass <- mkcclass_axi4lite();
    AXI4_Lite_Fabric_IFC #(`Num_Masters, `Num_Slaves, `paddr, XLEN, USERSPACE) 
                                                    fabric <- mkAXI4_Lite_Fabric(fn_slave_map);
		Ifc_memory_AXI4Lite#(`paddr, XLEN, USERSPACE, `Addr_space) main_memory <- mkmemory_AXI4Lite(
                                                      `MemoryBase, "code.mem.MSB", "code.mem.LSB");
		`ifdef BOOTROM
			Ifc_bootrom_AXI4Lite#(`paddr, XLEN, USERSPACE) bootrom <-mkbootrom_AXI4Lite(`BootRomBase);
		`endif

   	mkConnection(cclass.master_d,	fabric.v_from_masters[`Mem_master_num]);
   	mkConnection(cclass.master_i, fabric.v_from_masters[`Fetch_master_num]);

		mkConnection(fabric.v_to_slaves[`Memory_slave_num],main_memory.slave);
		`ifdef BOOTROM
			mkConnection (fabric.v_to_slaves [`BootRom_slave_num],bootrom.slave);
		`endif

    `ifdef simulate
      interface io_dump= cclass.io_dump;
    `endif
  endmodule: mkSoC
`endif
`ifdef CORE_TLU
  (*synthesize*)
  module mkSoC(Ifc_SoC);
    Ifc_cclass_TLU cclass <- mkcclass_TLU();
    // TODO do this somewhere better
    Vector#(`Num_Slaves, Bit#(`Num_Masters)) master_route; //encoding: IMEM, DMEM  
	  master_route[valueOf(`Memory_slave_num)]                    = truncate(2'b11);
	  master_route[valueOf(`Memory_wr_slave_num)]                 = truncate(2'b01);
	  `ifdef BOOTROM master_route[valueOf(`BootRom_slave_num)]     = truncate(2'b11); `endif

    Tilelink_Fabric_IFC_lite#(`Num_Masters, `Num_Slaves, 1, `paddr, TDiv#(XLEN, 8), 2) fabric <- 
                                                                      mkTilelinkLite(fn_slave_map,
                                                                      master_route);
	  Ifc_memory_TLU#(`paddr, TDiv#(XLEN, 8), 2, `Addr_space) main_memory <- mkmemory_TLU(`MemoryBase,
                                                                    "code.mem.MSB", "code.mem.LSB");	
		`ifdef BOOTROM
			Ifc_bootrom_TLU#(`paddr, TDiv#(XLEN, 8), 2) bootrom <-mkbootrom_TLU(`BootRomBase);
		`endif

   	mkConnection(cclass.mem_master,	fabric.v_from_masters[`Mem_master_num]);
   	mkConnection(cclass.fetch_master, fabric.v_from_masters[`Fetch_master_num]);

		mkConnection(fabric.v_to_slaves[`Memory_slave_num],main_memory.read_slave);
		mkConnection(fabric.v_to_slaves[`Memory_wr_slave_num],main_memory.write_slave);
		`ifdef BOOTROM
			mkConnection (fabric.v_to_slaves [`BootRom_slave_num],bootrom.slave);
		`endif

    `ifdef simulate
      interface dump= cclass.io_dump;
    `endif
  endmodule: mkSoC
`endif
endpackage: SoC
