/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module comb_filter_center #(
    parameter int IN_WIDTH = 12,
    parameter int CENTER_CODE = 2048
) (
    input  logic [IN_WIDTH-1:0]              in_sample,
    output logic signed [IN_WIDTH:0]         centered_sample
);

    localparam logic signed [IN_WIDTH:0] CENTER_SIGNED = CENTER_CODE;

    always_comb begin
        centered_sample = $signed({1'b0, in_sample}) - CENTER_SIGNED;
    end

endmodule
