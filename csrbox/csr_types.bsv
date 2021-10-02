
/*
See LICENSE for details
This file has been generated by CSR-BOX - 1.5.4
Time of Generation: 2021-10-02 15:34:55.358759
*/

package csr_types ;
    `include "csrbox.defines"
    `include "Logger.bsv"


    typedef struct {
        Bit#(12) csr_address;
        Bit#(64) writedata;
        Bit#(2) funct3;
        Bit#(1) pc_1;
    } CSRReq deriving(Bits, FShow, Eq);

    typedef struct{
        Bool hit;
        Bit#(64)  data;
    } CSRResponse deriving(Bits, Eq, FShow);

    typedef enum {Machine = 3, Supervisor = 1, User = 0} Privilege_mode deriving(Bits, Eq, FShow);


    function Bit#(64) fn_csr_op (Bit#(64) writedata, Bit#(64) readdata, Bit#(2) op);
        if(op == 'd1)
    	    return writedata;
        else if(op == 'd2)
            return (writedata|readdata);
        else
            return (~writedata & readdata);
    endfunction
  
endpackage 