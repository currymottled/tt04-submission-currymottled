`timescale 1ns / 1ps

module I2C_slave(
    input            clk, rst_n, ena,
    input            SCL_in, SDA_in,
    output reg       SCL_out, SDA_out,
    output reg       SCL_ena, SDA_ena,
    output reg [5:0] update_value, read_value,
    output reg [7:0] reg_addr, // addr[2:1] is 00 for P, 01 for I, and 10 for D. addr[0] is the ack bit.
    output reg [4:0] state
    );
    
    reg       read_or_write; // This stores the read/write bit.
    reg [6:0] device_addr;
    reg [2:0] addr_index, reg_index, data_index; // The indices are 7 bit (the MSB is the sixth).
    
    parameter DEVICE_ADDRESS = 7'b0110_011; // A made up placeholder.
    parameter K_p_ADDRESS = 8'b0000_0000;
    parameter K_i_ADDRESS = 8'b0000_0001;
    parameter K_d_ADDRESS = 8'b0000_0010;
    
    // State Parameters
    localparam IDLE          = 0;
	localparam START         = 1;
	localparam DEVICE_ADDR   = 2;
	localparam READ_OR_WRITE = 3;
	localparam ADDR_ACK      = 4;
	localparam REG_ADDR      = 5;
	localparam REG_ACK       = 6;
	localparam WRITE         = 7;
	localparam WRITE_ACK     = 8;
	localparam READ          = 9;
	localparam READ_ACK      = 10;
	localparam STOP          = 11;

 /*------------------------------------------ Postive Half Cycle -------------------------------------------*/
    always @ (posedge SCL_in) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    // Start the process if enabled.
                    if (ena) state <= START;  
                end           
                START: begin
                    // Start bit
                    if (SDA_in == 0) state <= DEVICE_ADDR;
                end
                DEVICE_ADDR: begin
                    // Send MSB first, LSB last.
                    if (addr_index == 0) begin
                        // Check the address is right, otherwise return to idling.
                        if (device_addr == DEVICE_ADDRESS) state <= ADDR_ACK;
                        else state <= IDLE;
                        addr_index <= 6;
                    end else addr_index <= addr_index - 1;
                end
                READ_OR_WRITE: begin
                    // If the master is writing, it sends 0, if it is reading it sends 1.
                    if (SDA_in == 0) read_or_write <= READ;
                    else read_or_write <= WRITE;
                    state <= ADDR_ACK;
                end            
                ADDR_ACK: begin
                    // The acknowledge bit is sent on the negative half cycle.
                    state <= REG_ADDR;
                end
                REG_ADDR: begin 
                    if (reg_index == 0) begin
                        // Check the address is a PID address, otherwise return to idling.
                        if ((reg_addr == K_p_ADDRESS) || (reg_addr == K_i_ADDRESS) || (reg_addr == K_d_ADDRESS)) begin
                            state <= REG_ACK;
                        end
                        else state <= IDLE;
                        reg_index <= 7;
                    end else reg_index <= reg_index - 1;
                end
                REG_ACK: begin
                    // The acknowledge bit is sent on the negative half cycle.
                    state <= read_or_write;
                end                 
                WRITE: begin
                    // The data is written on the negative half cycle, MSB first, and LSB last. 
                    if (data_index == 0) begin
                        data_index <= 7;
                        state <= WRITE_ACK;
                    end else data_index <= data_index - 1;
                    
                end              
                WRITE_ACK: begin
                    // Going to IDLE immediately, and through STOP, are not the same because of
                    // the negative half cycle.
                    if (SDA_in == 0) state <= STOP; // If the data is read, proceed.
					else state <= IDLE; // If the data was not read, the process should be reset. 
                end
                READ: begin
                    //The values are read in at the section on register reading.
                	SDA_out <= read_value[data_index];
					if (data_index == 0) begin
					   state <= READ_ACK;
					   data_index <= 7;
					end else data_index <= data_index - 1;
                end                
                READ_ACK: begin 
                    // The ACK is sent on the negative half-cycle.
                    state <= STOP;
                end
                STOP: begin 
                // Stop the process (return to idling) when the stop bit is sent.
                if (SDA_in == 1) state <= IDLE;        
                end           
           endcase
        end
    end
    /*------------------------------------------ Negative Half Cycle -------------------------------------------*/
    //START, STOP, ACKs, READ, WRITE (enable), and READ_OR_WRITE are handled by signal logic.
    always @ (negedge SCL_in) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if (ena) state <= START;                   
                end            
                DEVICE_ADDR: begin 
                    // Store the device address.                
                    device_addr[addr_index] <= SDA_in;
                end              
                REG_ADDR: begin
                    // Store the register adress.
                    reg_addr[reg_index] <= SDA_in;
                end
                WRITE: begin
                    update_value[data_index] <= SDA_in;
                end                                  
           endcase
        end
    end

endmodule
