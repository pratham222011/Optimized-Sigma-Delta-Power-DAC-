`timescale 1ns / 1ps

module tb_sigma_delta_dac_2nd;

    localparam WIDTH      = 8;
    localparam CLK_PERIOD = 10;
    localparam N_SAMPLES  = 4096;     // longer window → tighter average
    localparam TOLERANCE  = 4;         // ±4 LSB allowed

    reg              clk;
    reg              rst;
    reg  [WIDTH-1:0] din;
    wire             dout;

    sigma_delta_dac_2nd #(.WIDTH(WIDTH)) dut (
        .clk  (clk),
        .rst  (rst),
        .din  (din),
        .dout (dout)
    );

    // 100 MHz clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Simulated RC-filtered output (same trick as before)
    real vout_sim;
    initial vout_sim = 0.0;
    always @(posedge clk)
        vout_sim <= vout_sim + 0.01 * ((dout ? 3.3 : 0.0) - vout_sim);

    integer ones_count;
    integer i;
    integer errors;
    integer expected_ones;
    integer diff;

    task measure_duty(input [WIDTH-1:0] value);
        begin
            din        = value;
            ones_count = 0;

            // Settle: 2nd-order has more transient; give it time
            repeat (2 * N_SAMPLES) @(posedge clk);

            // Measurement window
            for (i = 0; i < N_SAMPLES; i = i + 1) begin
                @(posedge clk);
                if (dout) ones_count = ones_count + 1;
            end

            // Expected ones in N_SAMPLES window for input `value`:
            //   (value / 256) * N_SAMPLES
            expected_ones = (value * N_SAMPLES) / 256;
            diff = ones_count - expected_ones;
            if (diff < 0) diff = -diff;

            $display("din = %3d (0x%02h)  ones = %5d  expected ~%5d  diff = %3d  %s",
                     value, value, ones_count, expected_ones, diff,
                     (diff <= TOLERANCE) ? "PASS" : "FAIL");

            if (diff > TOLERANCE) errors = errors + 1;
        end
    endtask

    initial begin
        $dumpfile("tb_sigma_delta_dac_2nd.vcd");
        $dumpvars(0, tb_sigma_delta_dac_2nd);

        rst    = 1;
        din    = 0;
        errors = 0;
        repeat (8) @(posedge clk);
        rst = 0;

        $display("--- 2nd-Order Sigma-Delta DAC testbench ---");

        measure_duty(8'd0);
        measure_duty(8'd32);
        measure_duty(8'd64);
        measure_duty(8'd96);
        measure_duty(8'd128);
        measure_duty(8'd160);
        measure_duty(8'd192);
        measure_duty(8'd224);
        measure_duty(8'd255);

        $display("--- Done. %0d error(s). ---", errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("TESTS FAILED");

        $finish;
    end

    initial begin
        #20_000_000;     // 20 ms safety net
        $display("TIMEOUT"); $finish;
    end

endmodule
