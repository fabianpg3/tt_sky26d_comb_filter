/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module comb_filter_top #(
    parameter int AD1_SPI_CLK_DIV = 1,
    parameter int DA3_SPI_CLK_DIV = 1,
    parameter int ADC_DATA_WIDTH  = 12,
    parameter int DAC_DATA_WIDTH  = 13
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        ad1_d0,
    input  logic        ad1_d1,
    output logic        ad1_sclk,
    output logic        ad1_cs_n,

    output logic        da3_cs_n,
    output logic        da3_sclk,
    output logic        da3_sdin,
    output logic        da3_ldac_n,

    output logic        ad1_init_done,
    output logic        da3_init_done
);

    logic                      adc_valid;
    logic [ADC_DATA_WIDTH-1:0] adc_sample;
    logic [2:0]                adc_channel;

    logic                      filter_valid;
    logic [DAC_DATA_WIDTH-1:0] filter_sample;
    logic signed [DAC_DATA_WIDTH-1:0] filter_sample_signed;
    logic [ADC_DATA_WIDTH-1:0] mapped_dac_sample;
    logic [ADC_DATA_WIDTH-1:0] mapped_dac_sample_from_mapper;

    ad1_capture_top #(
        .SPI_CLK_DIV(AD1_SPI_CLK_DIV)
    ) u_ad1_capture_top (
        .clk(clk),
        .rst_n(rst_n),
        .ad1_d0(ad1_d0),
        .ad1_d1(ad1_d1),
        .ad1_sclk(ad1_sclk),
        .ad1_cs_n(ad1_cs_n),
        .init_done(ad1_init_done),
        .sample_valid(adc_valid),
        .sample_data(adc_sample),
        .sample_channel(adc_channel)
    );

    comb_filter_core #(
        .IN_WIDTH(ADC_DATA_WIDTH),
        .OUT_WIDTH(DAC_DATA_WIDTH),
        .CENTER_CODE(2048)
    ) u_comb_filter_core (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(adc_valid),
        .in_sample(adc_sample),
        .out_valid(filter_valid),
        .out_sample(filter_sample)
    );

    comb_filter_dac_mapper #(
        .IN_WIDTH(DAC_DATA_WIDTH),
        .OUT_WIDTH(ADC_DATA_WIDTH),
        .CENTER_CODE(2048),
        .GAIN_SHIFT(1)
    ) u_comb_filter_dac_mapper (
        .in_sample(filter_sample_signed),
        .out_sample(mapped_dac_sample_from_mapper)
    );
    assign filter_sample_signed = $signed(filter_sample);
    assign mapped_dac_sample = mapped_dac_sample_from_mapper;

    da3_output_top #(
        .SPI_CLK_DIV(DA3_SPI_CLK_DIV),
        .SAMPLE_WIDTH(ADC_DATA_WIDTH)
    ) u_da3_output_top (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(filter_valid),
        .in_sample(mapped_dac_sample),
        .init_done(da3_init_done),
        .out_update_pulse(),
        .da3_cs_n(da3_cs_n),
        .da3_sclk(da3_sclk),
        .da3_sdin(da3_sdin),
        .da3_ldac_n(da3_ldac_n)
    );

endmodule
