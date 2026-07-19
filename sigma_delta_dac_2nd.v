module sigma_delta_dac_2nd #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] din,
    output reg              dout
);
    localparam IW   = WIDTH + 10;
    localparam HALF = 1 << (WIDTH-1);
    localparam signed [IW-1:0] SAT_POS =  (1 <<< (IW-1)) - 1;
    localparam signed [IW-1:0] SAT_NEG = -(1 <<< (IW-1));
    // Centered input, bipolar 1-bit feedback
    wire signed [IW-1:0] x  = $signed({{(IW-WIDTH){1'b0}}, din}) - HALF;
    wire signed [IW-1:0] fb = dout ? HALF : -HALF;
    reg signed [IW-1:0] acc1, acc2;
    // Compute sums at IW+2 to prevent overflow before saturation
    wire signed [IW+1:0] s1_raw = {{2{acc1[IW-1]}}, acc1}
                                + {{2{x[IW-1]}},    x   }
                                - {{2{fb[IW-1]}},   fb  };
    wire signed [IW-1:0] s1_sat = (s1_raw >  $signed(SAT_POS)) ? SAT_POS :
                                  (s1_raw <  $signed(SAT_NEG)) ? SAT_NEG :
                                  s1_raw[IW-1:0];
    wire signed [IW+1:0] s2_raw = {{2{acc2[IW-1]}},   acc2  }
                                + {{2{s1_sat[IW-1]}}, s1_sat}
                                - {{2{fb[IW-1]}},     fb    };
    wire signed [IW-1:0] s2_sat = (s2_raw >  $signed(SAT_POS)) ? SAT_POS :
                                  (s2_raw <  $signed(SAT_NEG)) ? SAT_NEG :
                                  s2_raw[IW-1:0];
    always @(posedge clk) begin
        if (rst) begin
            acc1 <= 0;
            acc2 <= 0;
            dout <= 1'b0;
        end else begin
            acc1 <= s1_sat;
            acc2 <= s2_sat;
            dout <= (s2_sat >= 0);
        end
    end
endmodule
