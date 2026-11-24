/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module da3_output_top #(
    parameter int SPI_CLK_DIV = 8,
    parameter int SAMPLE_WIDTH = 16,
    parameter logic [15:0] INIT_CODE = 16'h8000
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    in_valid,
    input  logic [SAMPLE_WIDTH-1:0] in_sample,

    output logic                    init_done,
    output logic                    out_update_pulse,

    output logic                    da3_cs_n,
    output logic                    da3_sclk,
    output logic                    da3_sdin,
    output logic                    da3_ldac_n
);

    logic        spi_start;
    logic [15:0] spi_tx_data;
    logic        spi_busy;
    logic        spi_done;
    logic [15:0] spi_rx_data;

    logic        ldac_strobe_req;
    logic        ldac_strobe_busy;

    spi_master #(
        .MAX_BITS(16),
        .CPOL(1'b1),
        .CPHA(1'b1),
        .CS_HOLD_TICKS(1)
    ) u_spi_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi_start),
        .tx_data(spi_tx_data),
        .xfer_bits(6'd16),
        .busy(spi_busy),
        .done(spi_done),
        .rx_data(spi_rx_data),
        .spi_cs_n(),
        .spi_sclk(da3_sclk),
        .spi_mosi(da3_sdin),
        .spi_miso(1'b0)
    );

    da3_ldac_cs_controller u_ldac_cs_controller (
        .clk(clk),
        .rst_n(rst_n),
        .ldac_strobe_req(ldac_strobe_req),
        .spi_busy(spi_busy),
        .ldac_strobe_busy(ldac_strobe_busy),
        .da3_cs_n(da3_cs_n),
        .da3_ldac_n(da3_ldac_n)
    );

    da3_programmer_fsm #(
        .INIT_CODE(INIT_CODE),
        .SAMPLE_WIDTH(SAMPLE_WIDTH)
    ) u_da3_programmer_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .spi_start(spi_start),
        .spi_tx_data(spi_tx_data),
        .spi_busy(spi_busy),
        .spi_done(spi_done),
        .init_done(init_done),
        .sample_valid(in_valid),
        .sample_data(in_sample),
        .out_update_pulse(out_update_pulse),
        .ldac_strobe_req(ldac_strobe_req),
        .ldac_strobe_busy(ldac_strobe_busy)
    );

endmodule
