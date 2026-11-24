/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module comb_filter_register #(
    parameter int DATA_WIDTH = 24
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en,
    input  logic [DATA_WIDTH-1:0] d,
    output logic [DATA_WIDTH-1:0] q
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= '0;
        end else if (en) begin
            q <= d;
        end
    end

endmodule
