// Drives the Basys 3's 4-digit multiplexed common-anode 7-segment display.
// Shows an 8-bit value (0-255) as decimal on the 3 rightmost digits;
// leftmost digit is blanked.
module seg7_display #(
    parameter CLK_HZ     = 100_000_000,
    parameter REFRESH_HZ = 800   // per-digit switch rate; ~200Hz full-frame refresh
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] value,
    output reg  [6:0] seg,   // active-low: {CG,CF,CE,CD,CC,CB,CA} bit order below
    output reg        dp,    // active-low decimal point (unused, always off)
    output reg  [3:0] an     // active-low digit enable, an[0] = rightmost digit
);

    // ---- BCD conversion ----
    wire [3:0] hundreds, tens, units;
    bin_to_bcd8 bcd (
        .bin(value), .hundreds(hundreds), .tens(tens), .units(units)
    );

    // ---- Digit scan clock divider ----
    localparam integer DIV = CLK_HZ / (REFRESH_HZ * 4);
    reg [31:0] div_cnt;
    reg [1:0]  digit_sel;

    always @(posedge clk) begin
        if (rst) begin
            div_cnt   <= 0;
            digit_sel <= 0;
        end else if (div_cnt == DIV-1) begin
            div_cnt   <= 0;
            digit_sel <= digit_sel + 1'b1;
        end else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end

    // ---- Per-digit value mux ----
    reg [3:0] digit_val;
    reg       digit_blank;
    always @(*) begin
        case (digit_sel)
            2'd0: begin digit_val = units;    digit_blank = 1'b0; end // AN0
            2'd1: begin digit_val = tens;     digit_blank = 1'b0; end // AN1
            2'd2: begin digit_val = hundreds; digit_blank = 1'b0; end // AN2
            2'd3: begin digit_val = 4'd0;     digit_blank = 1'b1; end // AN3, blanked
        endcase
    end

    // ---- Anode select (active low, one-hot) ----
    always @(*) begin
        an = 4'b1111;
        an[digit_sel] = 1'b0;
    end

    // ---- 7-segment decode, active-low segments: seg = {g,f,e,d,c,b,a} ----
    always @(*) begin
        dp = 1'b1; // decimal point always off
        if (digit_blank) begin
            seg = 7'b1111111; // all segments off
        end else begin
            case (digit_val)
                4'd0: seg = 7'b1000000;
                4'd1: seg = 7'b1111001;
                4'd2: seg = 7'b0100100;
                4'd3: seg = 7'b0110000;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b0010010;
                4'd6: seg = 7'b0000010;
                4'd7: seg = 7'b1111000;
                4'd8: seg = 7'b0000000;
                4'd9: seg = 7'b0010000;
                default: seg = 7'b1111111;
            endcase
        end
    end

endmodule
