#pragma once

#include "utils/tensor_utils.hpp"

#ifdef LINUX_APP
#include <iostream>
#include "utils/trace.hpp"
#endif

template <
    int BRAM_W_I>
void copy_row(volatile uint32_t *dst, volatile uint32_t *src)
{
    for (int i = 0; i < BRAM_W_I; ++i)
        dst[i] = src[i];
}

template <
    int BRAM_H_I,
    int BRAM_W_I,
    typename stream_t,
    typename dim_t,
    typename pixel_pkg_t>
void axis_read_lines(
    stream_t &stream_i,
    const dim_t &frame_i_shape,
    pixel_pkg_t &px_in_q,
    volatile uint32_t *x_bram,
    int &row_abs,
    int &row_q,
    int &col_q,
    int &chunk_cnt,
    bool &frame_started,
    bool &endOfFrame)
{
    // Local coordinates
    int row = 0, col = 0;
    int32_t offset_r, offset_g, offset_b;
    int32_t src_offset_r, src_offset_g, src_offset_b;
    dim_t frame_i_index_r, frame_i_index_g, frame_i_index_b;

    // === Copy the previous line to the first line of the current chunk ===
    if (chunk_cnt)
    {
        // === compute source offsets ===
        frame_i_index_r.set(0, 0, BRAM_H_I - 1, 0);
        frame_i_index_g.set(0, 1, BRAM_H_I - 1, 0);
        frame_i_index_b.set(0, 2, BRAM_H_I - 1, 0);
        src_offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
        src_offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
        src_offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
        // === compute destination offsets ===
        frame_i_index_r.set(0, 0, 0, 0);
        frame_i_index_g.set(0, 1, 0, 0);
        frame_i_index_b.set(0, 2, 0, 0);
        offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
        offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
        offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
        // === copy last line into the first position ===
        copy_row<BRAM_W_I>(x_bram + offset_r, x_bram + src_offset_r);
        copy_row<BRAM_W_I>(x_bram + offset_g, x_bram + src_offset_g);
        copy_row<BRAM_W_I>(x_bram + offset_b, x_bram + src_offset_b);
        // === increment the row ===
        row = 1;
    }
    // === Compute tensor offsets ===
    frame_i_index_r.set(0, 0, row, 0);
    frame_i_index_g.set(0, 1, row, 0);
    frame_i_index_b.set(0, 2, row, 0);
    offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
    offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
    offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);

    while (row < BRAM_H_I)
    {
        // #pragma HLS PIPELINE II=1

        pixel_pkg_t px_in = px_in_q.user ? px_in_q : stream_i.read();

        // === Start of frame detection ===
        if (px_in.user == 1 && !frame_started)
        {
            frame_started = true;
            chunk_cnt = 0;
            px_in_q.user = 0;
            px_in.user = 0;
        }

        if (!frame_started)
            continue; // Wait for frame start

        // === Check for frame end ===
        if (px_in.user == 1)
        {
            // End of frame detected mid-stream (next frame starting)
            px_in_q = px_in;
            frame_started = false;
            endOfFrame = true;
            break;
        }

        // === Unpack RGB from 0x00RRGGBB ===
        uint8_t red = (px_in.data >> 16) & 0xFF;
        uint8_t green = (px_in.data >> 8) & 0xFF;
        uint8_t blue = (px_in.data) & 0xFF;

        // === Write to BRAM ===
        if (row < BRAM_H_I && col < BRAM_W_I)
        {
            x_bram[offset_r++] = red;
            x_bram[offset_g++] = green;
            x_bram[offset_b++] = blue;
        }

        // === Advance coordinates ===
        col++;
        if (px_in.last == 1)
        {
            row++;
            row_abs++;
            col_q = col; // width of last line
            col = 0;
            // === Compute tensor offsets ===
            frame_i_index_r.set(0, 0, row, 0);
            frame_i_index_g.set(0, 1, row, 0);
            frame_i_index_b.set(0, 2, row, 0);
            offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
            offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
            offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
        }
    }

    row_q = row;
    chunk_cnt += 1;
}
