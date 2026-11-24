/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module comb_filter_core #(
    parameter int IN_WIDTH = 12,
    parameter int OUT_WIDTH = 13,
    parameter int CENTER_CODE = 2048
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    in_valid,
    input  logic [IN_WIDTH-1:0]     in_sample,

    output logic                    out_valid,
    output logic [OUT_WIDTH-1:0]    out_sample
);

    localparam int DELAY_WIDTH = IN_WIDTH + 1;

    logic signed [DELAY_WIDTH-1:0] delayed_sample;
    logic signed [OUT_WIDTH-1:0]   adder_sum;
    logic signed [DELAY_WIDTH-1:0] centered_sample;
    logic                          accept_sample;

    always_comb begin
        accept_sample = rst_n && in_valid;
    end

    comb_filter_center #(
        .IN_WIDTH(IN_WIDTH),
        .CENTER_CODE(CENTER_CODE)
    ) u_center (
        .in_sample(in_sample),
        .centered_sample(centered_sample)
    );

    comb_filter_adder #(
        .A_WIDTH(DELAY_WIDTH),
        .B_WIDTH(DELAY_WIDTH),
        .SUM_WIDTH(OUT_WIDTH)
    ) u_adder (
        .a(centered_sample),
        .b(delayed_sample),
        .sum(adder_sum)
    );

    comb_filter_register #(
        .DATA_WIDTH(DELAY_WIDTH)
    ) u_delay_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(accept_sample),
        .d(centered_sample),
        .q(delayed_sample)
    );

    always_comb begin
        out_valid  = accept_sample;
        out_sample = adder_sum;
    end

endmodule
