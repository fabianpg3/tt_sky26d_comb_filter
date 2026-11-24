/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module tt_um_fabianpg3_comb_filter (
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,
    input  wire [7:0]  uio_in,
    output wire [7:0]  uio_out,
    output wire [7:0]  uio_oe,
    input  wire        ena,
    input  wire        clk,
    input  wire        rst_n
);

    logic ad1_d1;
    logic da3_ldac_n;
    logic ad1_d0;
    logic ad1_sclk;
    logic ad1_cs_n;
    logic da3_cs_n;
    logic da3_sclk;
    logic da3_sdin;

    logic design_reset_n;

    assign ad1_d0         = ui_in[0];
    assign ad1_d1         = ui_in[1];
    assign design_reset_n = rst_n && ena;

    assign uio_out = 8'h00;
    assign uio_oe  = 8'hFF;

    comb_filter_top #(
        .AD1_SPI_CLK_DIV(1),
        .DA3_SPI_CLK_DIV(1),
        .ADC_DATA_WIDTH(12),
        .DAC_DATA_WIDTH(13)
    ) u_comb_filter_top (
        .clk(clk),
        .rst_n(design_reset_n),
        .ad1_d1(ad1_d1),
        .ad1_d0(ad1_d0),
        .ad1_sclk(ad1_sclk),
        .ad1_cs_n(ad1_cs_n),
        .da3_cs_n(da3_cs_n),
        .da3_sclk(da3_sclk),
        .da3_sdin(da3_sdin),
        .da3_ldac_n(da3_ldac_n)
    );

    assign uo_out = {
        da3_ldac_n,
        1'b0,
        da3_sdin,
        da3_sclk,
        da3_cs_n,
        ad1_cs_n,
        ad1_sclk,
        1'b0
    };

endmodule
