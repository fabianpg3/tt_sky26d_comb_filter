/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module comb_filter_dac_mapper #(
    parameter int IN_WIDTH    = 14,
    parameter int OUT_WIDTH   = 12,
    parameter int CENTER_CODE = 2048,
    parameter int GAIN_SHIFT  = 1
) (
    input  logic signed [IN_WIDTH-1:0]  in_sample,
    output logic [OUT_WIDTH-1:0]        out_sample
);

    localparam int OUT_MAX = (1 << OUT_WIDTH) - 1;

    logic signed [IN_WIDTH-1:0] scaled_sample;
    logic signed [IN_WIDTH:0]   biased_sample;

    always_comb begin
        scaled_sample = in_sample >>> GAIN_SHIFT;
        biased_sample = scaled_sample + $signed(CENTER_CODE);

        if (biased_sample < 0) begin
            out_sample = '0;
        end else if (biased_sample > $signed(OUT_MAX)) begin
            out_sample = {OUT_WIDTH{1'b1}};
        end else begin
            out_sample = biased_sample[OUT_WIDTH-1:0];
        end
    end

endmodule
