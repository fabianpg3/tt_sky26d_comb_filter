/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module spi_master #(
    parameter int MAX_BITS = 32,
    parameter bit CPOL     = 1'b1,
    parameter bit CPHA     = 1'b1,
    parameter int CS_HOLD_TICKS = 0,
    parameter int FRAME_END_EXTRA_EDGES = 0
) (
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 start,
    input  logic [MAX_BITS-1:0]  tx_data,
    input  logic [5:0]           xfer_bits,

    output logic                 busy,
    output logic                 done,
    output logic [MAX_BITS-1:0]  rx_data,

    output logic                 spi_cs_n,
    output logic                 spi_sclk,
    output logic                 spi_mosi,
    input  logic                 spi_miso
);

    logic [5:0]                  bit_idx;
    logic [5:0]                  rx_bit_idx;
    logic [6:0]                  edge_cnt;
    logic [6:0]                  cs_hold_cnt;
    logic [MAX_BITS-1:0]         tx_shift;
    logic [MAX_BITS-1:0]         rx_shift;
    logic                        hold_cs_low;

    logic                        leading_edge;
    logic                        sample_edge;
    logic                        shift_edge;

    assign leading_edge = (edge_cnt[0] == 1'b0);
    assign sample_edge  = (CPHA == 1'b0) ? leading_edge : ~leading_edge;
    assign shift_edge   = (CPHA == 1'b0) ? ~leading_edge : leading_edge;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_idx   <= '0;
            rx_bit_idx <= '0;
            edge_cnt  <= '0;
            cs_hold_cnt <= '0;
            tx_shift  <= '0;
            rx_shift  <= '0;
            rx_data   <= '0;
            spi_cs_n  <= 1'b1;
            spi_sclk  <= CPOL;
            spi_mosi  <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
            hold_cs_low <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                edge_cnt <= '0;
                spi_sclk <= CPOL;

                if (start && (xfer_bits != 0) && (xfer_bits <= MAX_BITS)) begin
                    busy     <= 1'b1;
                    spi_cs_n <= 1'b0;
                    tx_shift <= tx_data;
                    rx_shift <= '0;
                    bit_idx  <= xfer_bits - 1'b1;
                    rx_bit_idx <= xfer_bits - 1'b1;
                    hold_cs_low <= 1'b0;
                    cs_hold_cnt <= '0;

                    if (CPHA == 1'b0) begin
                        spi_mosi <= tx_data[xfer_bits - 1'b1];
                    end else begin
                        spi_mosi <= 1'b0;
                    end
                end
            end else begin
                if (hold_cs_low) begin
                    spi_sclk <= CPOL;
                    if (cs_hold_cnt == 1) begin
                        hold_cs_low <= 1'b0;
                        busy        <= 1'b0;
                        done        <= 1'b1;
                        spi_cs_n    <= 1'b1;
                        rx_data     <= rx_shift;
                    end else begin
                        cs_hold_cnt <= cs_hold_cnt - 1'b1;
                    end
                end else begin
                    spi_sclk <= ~spi_sclk;

                    if (sample_edge) begin
                        rx_shift[rx_bit_idx] <= spi_miso;
                        if (rx_bit_idx != 0) begin
                            rx_bit_idx <= rx_bit_idx - 1'b1;
                        end
                    end

                    if (shift_edge) begin
                        if (CPHA == 1'b1) begin
                            spi_mosi <= tx_shift[bit_idx];
                        end

                        if (bit_idx != 0) begin
                            bit_idx <= bit_idx - 1'b1;
                            if (CPHA == 1'b0) begin
                                spi_mosi <= tx_shift[bit_idx - 1'b1];
                            end
                        end
                    end

                    if (edge_cnt == ((xfer_bits << 1) + FRAME_END_EXTRA_EDGES - 1'b1)) begin
                        spi_sclk <= CPOL;
                        if (CS_HOLD_TICKS > 0) begin
                            hold_cs_low <= 1'b1;
                            cs_hold_cnt <= CS_HOLD_TICKS[6:0];
                        end else begin
                            busy     <= 1'b0;
                            done     <= 1'b1;
                            spi_cs_n <= 1'b1;
                            rx_data  <= rx_shift;
                        end
                    end else begin
                        edge_cnt <= edge_cnt + 1'b1;
                    end
                end
            end
        end
    end

endmodule
