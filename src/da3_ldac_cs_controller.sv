/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

module da3_ldac_cs_controller (
    input  logic clk,
    input  logic rst_n,

    input  logic ldac_strobe_req,
    input  logic spi_busy,

    output logic ldac_strobe_busy,
    output logic da3_cs_n,
    output logic da3_ldac_n
);

    typedef enum logic [1:0] {
        DA3_LDAC_IDLE,
        DA3_LDAC_ASSERT_LOW,
        DA3_LDAC_RELEASE_HIGH,
        DA3_LDAC_POST_GAP
    } da3_ldac_state_t;


    da3_ldac_state_t ldac_state;
    logic da3_ldac_n_reg;
    logic force_cs_high;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ldac_state     <= DA3_LDAC_IDLE;
            da3_ldac_n_reg <= 1'b1;
            force_cs_high  <= 1'b0;
        end else begin
            case (ldac_state)
                DA3_LDAC_IDLE: begin
                    da3_ldac_n_reg <= 1'b1;
                    force_cs_high  <= 1'b0;
                    if (ldac_strobe_req) begin
                        force_cs_high <= 1'b1;
                        ldac_state    <= DA3_LDAC_ASSERT_LOW;
                    end
                end

                DA3_LDAC_ASSERT_LOW: begin
                    da3_ldac_n_reg <= 1'b0;
                    force_cs_high  <= 1'b1;
                    ldac_state     <= DA3_LDAC_RELEASE_HIGH;
                end

                DA3_LDAC_RELEASE_HIGH: begin
                    da3_ldac_n_reg <= 1'b1;
                    force_cs_high  <= 1'b1;
                    ldac_state     <= DA3_LDAC_POST_GAP;
                end

                DA3_LDAC_POST_GAP: begin
                    da3_ldac_n_reg <= 1'b1;
                    force_cs_high  <= 1'b1;
                    ldac_state     <= DA3_LDAC_IDLE;
                end

                default: begin
                    ldac_state     <= DA3_LDAC_IDLE;
                    da3_ldac_n_reg <= 1'b1;
                    force_cs_high  <= 1'b0;
                end
            endcase
        end
    end

    assign ldac_strobe_busy = (ldac_state != DA3_LDAC_IDLE);
    assign da3_ldac_n       = da3_ldac_n_reg;
    // Keep CS high until SPI reports busy. This avoids a one-cycle CS low pulse
    // caused by spi_start preceding spi_busy assertion.
    assign da3_cs_n         = force_cs_high ? 1'b1 : ~spi_busy;

endmodule
