/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module comb_filter_adder #(
    parameter int A_WIDTH   = 13,
    parameter int B_WIDTH   = 13,
    parameter int SUM_WIDTH = 14
) (
    input  logic signed [A_WIDTH-1:0]   a,
    input  logic signed [B_WIDTH-1:0]   b,
    output logic signed [SUM_WIDTH-1:0] sum
);

    always_comb begin
        sum = $signed(a) + $signed(b);
    end

endmodule
