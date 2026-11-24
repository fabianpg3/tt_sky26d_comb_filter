/*
 * Copyright (c) 2026 Fabian Alberto Picado Garcia
 * SPDX-License-Identifier: Apache-2.0
 */

package comb_filter_pkg;

    typedef enum logic [2:0] {
        AD1_ST_CS_HIGH_WAIT,
        AD1_ST_READ,
        AD1_ST_PUBLISH
    } ad1_state_t;

    typedef enum logic [2:0] {
        DA3_ST_INIT_WRITE,
        DA3_ST_WAIT_INIT,
        DA3_ST_IDLE,
        DA3_ST_WRITE_SAMPLE,
        DA3_ST_WAIT_SAMPLE,
        DA3_ST_WAIT_LDAC_ASSERT,
        DA3_ST_WAIT_LDAC_DONE
    } da3_state_t;

    typedef enum logic [1:0] {
        DA3_LDAC_IDLE,
        DA3_LDAC_ASSERT_LOW,
        DA3_LDAC_RELEASE_HIGH,
        DA3_LDAC_POST_GAP
    } da3_ldac_state_t;

endpackage
