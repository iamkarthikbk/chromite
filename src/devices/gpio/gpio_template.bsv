/* 
Copyright (c) 2013, InCore Semiconductors All rights reserved.

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

Author: Aditya Mathur
Email id: 
Details:

mmap-start
slave_bound: 16 bytes

schema-start
module:
    type: string
    regex: ^gpio$
type:
    type: string
    regex: ^device$
clusters:
    type: list
    schema:
        type: string
roles:
    type: dict
    schema:
        master:
            type: list
            schema:
                type: string
                regex: ^null$
                nullable: True
        slave:
            type: list
parameters:
    type: dict
    schema:
        ionum:
            type: integer
            max: 64
schema-end
--------------------------------------------------------------------------------------------------
*/

package gpio_template;
	`include "gpio.defines"
	import gpio::*;
	(*synthesize*)
	module mkdummy(Empty);
		 Ifc_gpio_axi4lite#(32,32,0,60) gpio1 <- mkgpio_axi4lite;
		 Ifc_gpio_axi4#(32,32,0,30) gpio2 <- mkgpio_axi4;
     //User_ifc#(32,32,64) gpio <- mkgpio;
	endmodule
endpackage
