#pragma once

#include "utils/tensor_utils.hpp"

template <
    int BRAM_H_I,
    int BRAM_W_I,
    typename stream_t,
    typename dim_t,
    typename pixel_pkg_t>
void axis_read_frame(stream_t &stream_i, const dim_t &frame_i_shape, pixel_pkg_t &px_in_q, volatile uint32_t *x_bram, int &row_q, int &col_q, bool &frame_started)
{
    // === Read one frame ===

    int row = 0, col = 0;
    int32_t offset_r, offset_g, offset_b;
    dim_t frame_i_index_r, frame_i_index_g, frame_i_index_b;

    while (true)
    {
        // #pragma HLS PIPELINE II=1

        pixel_pkg_t px_in = px_in_q.user ? px_in_q : stream_i.read();

        // Detect start of frame
        if (px_in.user == 1 && !frame_started)
        {
            frame_started = true;
            px_in_q.user = 0;
            px_in.user = 0;
            row = 0;
            col = 0;
            frame_i_index_r.set(0, 0, 0, 0);
            frame_i_index_g.set(0, 1, 0, 0);
            frame_i_index_b.set(0, 2, 0, 0);

            offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
            offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
            offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
        }

        if (frame_started)
        {

            if (px_in.user == 1)
            {
                row_q = row;
                px_in_q = px_in;
                frame_started = false;
                break; // // End of frame
            }
            // === Unpack RGB from 0x00RRGGBB ===
            uint8_t red = (px_in.data >> 16) & 0xFF;
            uint8_t green = (px_in.data >> 8) & 0xFF;
            uint8_t blue = (px_in.data) & 0xFF;

            // === Store into x_bram ===
            if (row < BRAM_H_I && col < BRAM_W_I)
            {
                x_bram[offset_r++] = red;

                x_bram[offset_g++] = green;

                x_bram[offset_b++] = blue;
            }
            // === Update coordinates ===
            col++;
            if (px_in.last == 1)
            {
                row++;
                col_q = col;
                col = 0;
                frame_i_index_r.set(0, 0, row, 0);
                frame_i_index_g.set(0, 1, row, 0);
                frame_i_index_b.set(0, 2, row, 0);

                offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
                offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
                offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
            }
        }
    }
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
    int &row_q,
    int &col_q,
    bool &frame_started,
    bool &endOfFrame)
{
    // Local coordinates
    int row = 0, col = 0;
    int32_t offset_r, offset_g, offset_b;
    dim_t frame_i_index_r, frame_i_index_g, frame_i_index_b;

    endOfFrame = false;
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
            col_q = col; // width of last line
            col = 0;
            // === Compute tensor offsets ===
            frame_i_index_r.set(0, 0, row, 0);
            frame_i_index_g.set(0, 1, row, 0);
            frame_i_index_b.set(0, 2, row, 0);
            offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
            offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
            offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);

            if (row >= BRAM_H_I)
                break;
        }
    }

    row_q = row;
}
