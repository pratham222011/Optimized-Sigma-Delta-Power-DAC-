// 8-bit binary to 3-digit BCD (double-dabble / shift-add-3 algorithm)
// Converts 0-255 -> hundreds, tens, units decimal digits.
module bin_to_bcd8 (
    input  wire [7:0] bin,
    output reg  [3:0] hundreds,
    output reg  [3:0] tens,
    output reg  [3:0] units
);
    integer i;
    reg [19:0] shift; // [19:16]=hundreds [15:12]=tens [11:8]=units [7:0]=bin being shifted in

    always @(*) begin
        shift = 20'd0;
        shift[7:0] = bin;
        for (i = 0; i < 8; i = i + 1) begin
            if (shift[11:8]  >= 5) shift[11:8]  = shift[11:8]  + 3;
            if (shift[15:12] >= 5) shift[15:12] = shift[15:12] + 3;
            if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
            shift = shift << 1;
        end
        hundreds = shift[19:16];
        tens     = shift[15:12];
        units    = shift[11:8];
    end
endmodule
