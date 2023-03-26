`timescale 1ns / 1ps

module button_status (
    input clk,                 // input clock
    input reset,               // reset signal
    input button,              // input button
    output reg status,         // binary output
    input initial_status       // initial state of the output
);

// Debounce constants
parameter COUNT_MAX = 14;    // number of clock cycles to sample the button
parameter THRESHOLD = 8;     // count threshold to determine if button has been pressed or released

// State registers
reg [3:0] count;             // debounce counter
reg last_button;             // button state in last sample
reg last_last_button;        // button state in second-to-last sample

// Debounce logic
always @(posedge clk, posedge reset) begin
    if (reset) begin
        count <= 0;
        last_button <= 0;
        last_last_button <= 0;
        status <= initial_status;
    end else begin
        if (button != last_button) begin
            count <= count + 1;
            if (count == COUNT_MAX) begin
                last_last_button <= last_button;
                last_button <= button;
                count <= 0;
            end
        end else begin
            last_last_button <= last_button;
            last_button <= button;
            count <= 0;
        end
        
        // Change binary output state when button is released
        if (last_last_button && !last_button && status == 0) begin
            status <= 1;
        end else if (last_last_button && !last_button && status == 1) begin
            status <= 0;
        end
    end
end

endmodule
