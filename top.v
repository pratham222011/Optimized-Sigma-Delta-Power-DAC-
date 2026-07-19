// Top-level for Basys 3
// - 8 slide switches drive the DAC input
// - Center pushbutton resets the modulator and display
// - Pmod JA pin 1 outputs the 1-bit PDM stream (feed into RC filter)
// - LEDs LD0..LD7 mirror the switch values
// - 7-segment display shows the current switch value (0-255) in decimal
module top (
    input  wire        clk_100mhz,
    input  wire        btn_reset,
    input  wire [7:0]  sw,
    output wire        pdm_out,
    output wire [7:0]  led,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an
);

    sigma_delta_dac_2nd #(.WIDTH(8)) u_dac (
        .clk  (clk_100mhz),
        .rst  (btn_reset),
        .din  (sw),
        .dout (pdm_out)
    );

    seg7_display #(
        .CLK_HZ(100_000_000),
        .REFRESH_HZ(800)
    ) u_disp (
        .clk   (clk_100mhz),
        .rst   (btn_reset),
        .value (sw),
        .seg   (seg),
        .dp    (dp),
        .an    (an)
    );

    // Mirror switch state on LEDs so you can confirm the input is correct
    assign led = sw;

endmodule
