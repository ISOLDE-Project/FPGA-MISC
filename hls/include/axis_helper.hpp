#pragma once

#include "utils/tensor_utils.hpp"

#ifdef LINUX_APP
#include "utils/trace.hpp"
#include <iostream>
#endif



template <int BRAM_H_I, int BRAM_W_I, typename stream_t, typename dim_t,
          typename pixel_pkg_t>
void axis_read_lines(stream_t &stream_i, const dim_t &frame_i_shape,
                     pixel_pkg_t &px_in_q, volatile uint32_t *x_bram,
                     int &row_abs, int &row_q, int &col_q, int &chunk_cnt,
                     bool &frame_started, bool &endOfFrame) {
  // Local coordinates
  int row = 0, col = 0;
  int32_t offset_r /* , offset_g, offset_b */;
  int32_t src_offset_r /* , src_offset_g, src_offset_b */;
  dim_t frame_i_index_r /* , frame_i_index_g, frame_i_index_b */;

  // === Compute tensor offsets ===
  frame_i_index_r.set(0, 0, row, 0);
  // frame_i_index_g.set(0, 1, row, 0);
  // frame_i_index_b.set(0, 2, row, 0);
  offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
  // offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
  // offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);

  while (row <= BRAM_H_I) {
    // #pragma HLS PIPELINE II=1

    pixel_pkg_t px_in = px_in_q.user ? px_in_q : stream_i.read();

    // === Start of frame detection ===
    if (px_in.user == 1 && !frame_started) {
      frame_started = true;
      chunk_cnt = 0;
      px_in_q.user = 0;
      px_in.user = 0;
    }

    if (!frame_started)
      continue; // Wait for frame start

    // === Check for frame end ===
    if (px_in.user == 1) {

      px_in_q = px_in;
      frame_started = false;
      endOfFrame = true;
      break;
    }

    // === Unpack RGB from 0x00RRGGBB ===
    // uint8_t red = (px_in.data >> 16) & 0xFF;
    // uint8_t green = (px_in.data >> 8) & 0xFF;
    // uint8_t blue = (px_in.data) & 0xFF;

    // ===  Format: pixel0 | pixel1 | pixel2 | pixel3
    // Most significant byte = pixel0, least significant = pixel3

    uint8_t pixel3 = (px_in.data >> 24) & 0xFF;
    uint8_t pixel2 = (px_in.data >> 16) & 0xFF;
    uint8_t pixel1 = (px_in.data >> 8) & 0xFF;
    uint8_t pixel0 = (px_in.data) & 0xFF;

    // === Write to BRAM ===
    if (row < BRAM_H_I && col < BRAM_W_I) {
      // x_bram[offset_r++] = red;
      // x_bram[offset_g++] = green;
      // x_bram[offset_b++] = blue;
      x_bram[offset_r++] = pixel0;
      x_bram[offset_r++] = pixel1;
      x_bram[offset_r++] = pixel2;
      x_bram[offset_r++] = pixel3;
    }

    // === Advance coordinates ===
    col += 4;
    if (px_in.last == 1) {
      row++;
      row_abs++;
      col_q = col; // width of last line
      col = 0;
      // === Compute tensor offsets ===
      frame_i_index_r.set(0, 0, row, 0);
      // frame_i_index_g.set(0, 1, row, 0);
      // frame_i_index_b.set(0, 2, row, 0);
      offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
      // offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
      // offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
    }
  }

  row_q = row;
  chunk_cnt += 1;
}

// === matrix to axis ===

namespace {
// Primary template: applies to all types except bool
template <typename T> struct UserField {
  static void set(T &user, uint32_t frame_cnt, bool sof) {
    user = (frame_cnt << 1) | (sof ? 1 : 0);
  }
  static void get(const T user, uint32_t &frame_cnt, bool &sof) {
    frame_cnt = (user >> 1);
    sof = user & 1;
  }
};

// Partial specialization for bool
template <> struct UserField<bool> {
  static void set(bool &user, uint32_t, bool sof) { user = sof; }
  static void get(const bool user, uint32_t &frame_cnt, bool &sof) {
    frame_cnt = 0; // always 0
    sof = user;
  }
};
} // namespace
template <typename T> void set_SOF(T &user, uint32_t frame_cnt, bool sof) {
  UserField<T>::set(user, frame_cnt, sof);
}

template <typename T>
void get_SOF(const T user, uint32_t &frame_cnt, bool &sof) {
  UserField<T>::get(user, frame_cnt, sof);
}

template <typename pixel_pkg_t, int FRAME_W, typename stream_t>
void matrix_to_axis(stream_t &stream_o, volatile uint32_t *y_bram, int last_row,
                    uint32_t frame_cnt, bool en_SOF) {
  // Format: pixel0 | pixel1 | pixel2 | pixel3
  static constexpr int BRAM_W = FRAME_W / 4;
  uint32_t offset = 0;
  for (int i = 0; i < last_row; ++i) {

    offset = i * BRAM_W;
    for (int j = 0; j < BRAM_W; ++j) {
      pixel_pkg_t px;
      px.data = y_bram[offset++];
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == BRAM_W - 1) ? 1 : 0; // End of each line
      // px.user = en_SOF && (i == 0 && j == 0) ? 1 : 0; // Start of frame only
      bool sof = en_SOF && ((i == 0 && j == 0) ? 1 : 0); // Start of frame only
      set_SOF(px.user, frame_cnt, sof);
      stream_o.write(px);
    }
  }
}

// === crop frame
// === output stream ===
// static constexpr int VGA_H = 480;
// static constexpr int VGA_W = 640;
static constexpr int VGA_C = 1;
static constexpr int VGA_H = 224;
static constexpr int VGA_W = 224;

template <typename pixel_pkg_t, int BRAM_H, int BRAM_W, typename stream_t>
void vga_to_axis(stream_t &stream_o, volatile uint32_t *y_bram, int& row_out,int last_row) {
  static constexpr int j_start = (BRAM_W - VGA_W) / 2;
  static constexpr int j_end = j_start + VGA_W;
  static_assert(j_end < BRAM_W, "Crop not possible allong y axis");
  static constexpr int top_row = (BRAM_H - VGA_H) / 2;
  static constexpr int bottom_row = top_row + VGA_H ;
  uint32_t offset = 0;
  
    
  for (int i = 0; i < last_row; ++i) {

    if(row_out<top_row){
        row_out++;
        continue;
    }
    if(row_out>=bottom_row){
        continue;
    }
    
    offset = i * BRAM_W + j_start;

    for (int j = j_start; j < j_end; j += 4) {

      uint32_t p0 = y_bram[offset++] & 0xFF;
      uint32_t p1 = y_bram[offset++] & 0xFF;
      uint32_t p2 = y_bram[offset++] & 0xFF;
      uint32_t p3 = y_bram[offset++] & 0xFF;

      uint32_t packed = (p3 << 24) | (p2 << 16) | (p1 << 8) | p0;
      pixel_pkg_t px;
      px.data = packed;
      px.keep = -1; // All bytes valid
      px.strb = -1;
      px.id = 0;
      px.dest = 0;
      px.last = (j == j_end - 4) ? 1 : 0;               // End of each line
      px.user = (row_out == top_row && j == j_start) ? 1 : 0; // Start of frame only
      stream_o.write(px);
    }
    row_out++;
  }
}
