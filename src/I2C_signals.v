`timescale 1ns / 1ps

/*
This handles the I2C signals on the negative half cycle of the clock line, depending 
on slave state, mostly write and read enables for ACK bits and reading in data.

"Write" means "read in and write to a register", not "write to the master". 
"Read" means "read out to the master".
*/

module I2C_signals(
    input             clk, rst_n, ena,
    input  wire [4:0] state,
    input  wire       SCL_in, SDA_in, 
    output reg        SCL_out, SDA_out, 
    output reg        SCL_ena, SDA_ena // These are connected to the enable path of the chip.
    );
    
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
	

    
    // Reset
    always @ (posedge clk) begin
        if(!rst_n) begin
            SCL_out <= 0;
            SDA_out <= 0;
            SCL_ena <= 0;
            SDA_ena <= 0;      
        end
    end
    // Signal Logic    
    always @ (negedge SCL_in) begin
        if (ena) begin
            case(state)         
                START: begin
                    // Set SDA to input to read the start bit.
                    SDA_ena <= 0;
                end            
                ADDR_ACK: begin
                    // Send the ACK.
                    SDA_ena <= 1;
                    SDA_out <= 0; 
                end
                READ_OR_WRITE: begin
                    // Set SDA to input to read the read_or_write bit.
                    SDA_ena <= 0;
                end
                REG_ACK: begin
                    // Send the ACK.
                    SDA_ena <= 1;
                    SDA_out <= 0; 
                end
                WRITE: begin
                    // "Write" means "read in and write to a register", not "write to the master". 
                    SDA_ena <= 0;
                end              
                WRITE_ACK: begin
                    // Eable writing to send the ACK.
                    SDA_ena <= 1;
                    SDA_out <= 0;    
                end
                READ: begin
                    // "Read" means "read out to the master".
                    SDA_ena <= 1;     
                end
                READ_ACK: begin
                    // Enable writing to send the ACK.
                    SDA_ena <= 1;
                    SDA_out <= 0;
                end              
                STOP: begin
                    // Set SDA to input to read the stop bit.
                    SDA_ena <= 0;
                end              
           endcase
        end
    end
endmodule
