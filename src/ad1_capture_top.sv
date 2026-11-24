/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module ad1_capture_top #(
    parameter int SPI_CLK_DIV = 8
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        ad1_d0,
    input  logic        ad1_d1,
    output logic        ad1_sclk,
    output logic        ad1_cs_n,

    output logic        init_done,

    output logic        sample_valid,
    output logic [11:0] sample_data,
    output logic [2:0]  sample_channel
);

    logic        spi_start;
    logic [31:0] spi_tx_data;
    logic [5:0]  spi_xfer_bits;
    logic        spi_busy;
    logic        spi_done;
    logic [31:0] spi_rx_data;

    logic        fsm_sample_valid;
    logic [11:0] fsm_sample_data;
    logic [2:0]  fsm_sample_channel;
    logic        spi_mosi_unused;

    spi_master #(
        .MAX_BITS(32),
        .CPOL(1'b1),
        .CPHA(1'b1),
        .CS_HOLD_TICKS(2),
        .FRAME_END_EXTRA_EDGES(1)
    ) u_spi_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi_start),
        .tx_data(spi_tx_data),
        .xfer_bits(spi_xfer_bits),
        .busy(spi_busy),
        .done(spi_done),
        .rx_data(spi_rx_data),
        .spi_cs_n(ad1_cs_n),
        .spi_sclk(ad1_sclk),
        .spi_mosi(spi_mosi_unused),
        .spi_miso(ad1_d0)
    );

    ad1_programmer_fsm #(
        .SAMPLE_BITS(12),
        .CHANNEL_SEL(0),
        .CS_HIGH_CYCLES(2 * SPI_CLK_DIV)
    ) u_prog_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .dout_rdy_n(1'b0),
        .spi_start(spi_start),
        .spi_tx_data(spi_tx_data),
        .spi_xfer_bits(spi_xfer_bits),
        .spi_busy(spi_busy),
        .spi_done(spi_done),
        .spi_rx_data(spi_rx_data[15:0]),
        .init_done(init_done),
        .sample_valid(fsm_sample_valid),
        .sample_data(fsm_sample_data),
        .sample_channel(fsm_sample_channel)
    );

    assign sample_valid   = fsm_sample_valid;
    assign sample_data    = fsm_sample_data;
    assign sample_channel = fsm_sample_channel;

endmodule
