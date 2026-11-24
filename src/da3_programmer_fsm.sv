/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module da3_programmer_fsm #(
    parameter logic [15:0] INIT_CODE = 16'h8000,
    parameter int SAMPLE_WIDTH = 16
) (
    input  logic        clk,
    input  logic        rst_n,

    output logic        spi_start,
    output logic [15:0] spi_tx_data,
    input  logic        spi_busy,
    input  logic        spi_done,

    output logic        init_done,

    input  logic        sample_valid,
    input  logic [SAMPLE_WIDTH-1:0] sample_data,

    output logic        out_update_pulse,
    output logic        ldac_strobe_req,
    input  logic        ldac_strobe_busy
);

    typedef enum logic [2:0] {
        DA3_ST_INIT_WRITE,
        DA3_ST_WAIT_INIT,
        DA3_ST_IDLE,
        DA3_ST_WRITE_SAMPLE,
        DA3_ST_WAIT_SAMPLE,
        DA3_ST_WAIT_LDAC_ASSERT,
        DA3_ST_WAIT_LDAC_DONE
    } da3_state_t;

    da3_state_t state;
    logic   xfer_active;
    localparam int PAD_WIDTH = (16 > SAMPLE_WIDTH) ? (16 - SAMPLE_WIDTH) : 0;
    localparam int TX_START  = (SAMPLE_WIDTH > 16) ? (SAMPLE_WIDTH - 16) : 0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= DA3_ST_INIT_WRITE;
            xfer_active      <= 1'b0;
            spi_start        <= 1'b0;
            spi_tx_data      <= 16'h0000;
            init_done        <= 1'b0;
            out_update_pulse <= 1'b0;
            ldac_strobe_req  <= 1'b0;
        end else begin
            spi_start        <= 1'b0;
            out_update_pulse <= 1'b0;
            ldac_strobe_req  <= 1'b0;

            case (state)
                DA3_ST_INIT_WRITE: begin
                    if (!spi_busy && !xfer_active) begin
                        spi_tx_data <= INIT_CODE;
                        spi_start   <= 1'b1;
                        xfer_active <= 1'b1;
                        state       <= DA3_ST_WAIT_INIT;
                    end
                end

                DA3_ST_WAIT_INIT: begin
                    if (xfer_active && spi_done) begin
                        xfer_active <= 1'b0;
                        init_done   <= 1'b1;
                        state       <= DA3_ST_IDLE;
                    end
                end

                DA3_ST_IDLE: begin
                    if (sample_valid && !spi_busy && !xfer_active && !ldac_strobe_busy) begin
                        if (SAMPLE_WIDTH == 16) begin
                            spi_tx_data <= sample_data;
                        end else if (SAMPLE_WIDTH > 16) begin
                            spi_tx_data <= sample_data[SAMPLE_WIDTH-1 : TX_START];
                        end else begin
                            spi_tx_data <= {sample_data, {PAD_WIDTH{1'b0}}};
                        end
                        spi_start    <= 1'b1;
                        xfer_active  <= 1'b1;
                        state        <= DA3_ST_WAIT_SAMPLE;
                    end
                end

                DA3_ST_WAIT_SAMPLE: begin
                    if (xfer_active && spi_done) begin
                        xfer_active      <= 1'b0;
                        out_update_pulse <= 1'b1;
                        ldac_strobe_req  <= 1'b1;
                        state            <= DA3_ST_WAIT_LDAC_ASSERT;
                    end
                end

                DA3_ST_WAIT_LDAC_ASSERT: begin
                    if (ldac_strobe_busy) begin
                        state <= DA3_ST_WAIT_LDAC_DONE;
                    end
                end

                DA3_ST_WAIT_LDAC_DONE: begin
                    if (!ldac_strobe_busy) begin
                        state <= DA3_ST_IDLE;
                    end
                end

                default: begin
                    state <= DA3_ST_INIT_WRITE;
                end
            endcase
        end
    end

endmodule
