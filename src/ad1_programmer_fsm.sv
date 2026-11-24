/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module ad1_programmer_fsm #(
    parameter int SAMPLE_BITS = 12,
    parameter int CHANNEL_SEL = 0,
    parameter int CS_HIGH_CYCLES = 16
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        dout_rdy_n,

    output logic        spi_start,
    output logic [31:0] spi_tx_data,
    output logic [5:0]  spi_xfer_bits,
    input  logic        spi_busy,
    input  logic        spi_done,
    input  logic [15:0] spi_rx_data,

    output logic        init_done,
    output logic        sample_valid,
    output logic [11:0] sample_data,
    output logic [2:0]  sample_channel
);

    typedef enum logic [2:0] {
        AD1_ST_CS_HIGH_WAIT,
        AD1_ST_READ,
        AD1_ST_PUBLISH
    } ad1_state_t;

    ad1_state_t state;
    localparam int CS_WAIT_W = (CS_HIGH_CYCLES <= 1) ? 1 : $clog2(CS_HIGH_CYCLES + 1);
    logic [CS_WAIT_W-1:0] cs_high_cnt;

    assign sample_channel = CHANNEL_SEL[2:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= AD1_ST_CS_HIGH_WAIT;
            spi_start      <= 1'b0;
            spi_tx_data    <= 32'h00000000;
            spi_xfer_bits  <= 6'd0;
            init_done      <= 1'b0;
            sample_valid   <= 1'b0;
            sample_data    <= 12'h0;
            cs_high_cnt    <= CS_HIGH_CYCLES;
        end else begin
            spi_start    <= 1'b0;
            sample_valid <= 1'b0;

            case (state)
                AD1_ST_CS_HIGH_WAIT: begin
                    if (CS_HIGH_CYCLES > 0 && cs_high_cnt != 0) begin
                        cs_high_cnt <= cs_high_cnt - 1'b1;
                    end else if (!spi_busy) begin
                        spi_tx_data   <= 32'h00000000;
                        spi_xfer_bits <= 6'd16;
                        spi_start     <= 1'b1;
                        cs_high_cnt   <= CS_HIGH_CYCLES;
                        state         <= AD1_ST_READ;
                    end
                end

                AD1_ST_READ: begin
                    if (spi_done) begin
                        init_done    <= 1'b1;
                        // DB11 is read on rising edge 4, DB0 on rising edge 15. Rising edge 16 follows SDATA release; discard that tail.
                        sample_data  <= spi_rx_data[12:1];
                        state        <= AD1_ST_PUBLISH;
                    end
                end

                AD1_ST_PUBLISH: begin
                    sample_valid <= 1'b1;
                    state        <= AD1_ST_CS_HIGH_WAIT;
                end

                default: begin
                    state <= AD1_ST_CS_HIGH_WAIT;
                end
            endcase
        end
    end

endmodule
