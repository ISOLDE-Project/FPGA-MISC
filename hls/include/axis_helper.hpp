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
    int32_t offset_r/* , offset_g, offset_b */;
    int32_t src_offset_r/* , src_offset_g, src_offset_b */;
    dim_t frame_i_index_r/* , frame_i_index_g, frame_i_index_b */;

    // // === Copy the previous line to the first line of the current chunk ===
    // if (chunk_cnt)
    // {
    //     // === compute source offsets ===
    //     frame_i_index_r.set(0, 0, BRAM_H_I - 1, 0);
    //     // frame_i_index_g.set(0, 1, BRAM_H_I - 1, 0);
    //     // frame_i_index_b.set(0, 2, BRAM_H_I - 1, 0);
    //     src_offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
    //     // src_offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
    //     // src_offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
    //     // === compute destination offsets ===
    //     frame_i_index_r.set(0, 0, 0, 0);
    //     // frame_i_index_g.set(0, 1, 0, 0);
    //     // frame_i_index_b.set(0, 2, 0, 0);
    //     offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
    //     // offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
    //     // offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);
    //     // === copy last line into the first position ===
    //     copy_row<BRAM_W_I>(x_bram + offset_r, x_bram + src_offset_r);
    //     // copy_row<BRAM_W_I>(x_bram + offset_g, x_bram + src_offset_g);
    //     // copy_row<BRAM_W_I>(x_bram + offset_b, x_bram + src_offset_b);
    //     // === increment the row ===
    //     row = 1;
    // }
    // === Compute tensor offsets ===
    frame_i_index_r.set(0, 0, row, 0);
    // frame_i_index_g.set(0, 1, row, 0);
    // frame_i_index_b.set(0, 2, row, 0);
    offset_r = tensor_index_to_offset(frame_i_shape, frame_i_index_r);
    // offset_g = tensor_index_to_offset(frame_i_shape, frame_i_index_g);
    // offset_b = tensor_index_to_offset(frame_i_shape, frame_i_index_b);

    while (row <= BRAM_H_I)
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

        uint8_t pixel0 = (px_in.data >> 24) & 0xFF;
        uint8_t pixel1 = (px_in.data >> 16) & 0xFF;
        uint8_t pixel2 = (px_in.data >> 8) & 0xFF;
        uint8_t pixel3 = (px_in.data) & 0xFF;

    
    

        // === Write to BRAM ===
        if (row < BRAM_H_I && col < BRAM_W_I)
        {
            // x_bram[offset_r++] = red;
            // x_bram[offset_g++] = green;
            // x_bram[offset_b++] = blue;
            x_bram[offset_r++] = pixel0;
            x_bram[offset_r++] = pixel1;
            x_bram[offset_r++] = pixel2;
            x_bram[offset_r++] = pixel3;
        }

        // === Advance coordinates ===
        col+=4;
        if (px_in.last == 1)
        {
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
template <typename T>
struct UserField {
    static void set(T &user, uint32_t frame_cnt, bool sof) {
        user = (frame_cnt << 1) | ( sof ? 1 : 0);
    }
    static void get(const T user, uint32_t& frame_cnt, bool& sof) {
        frame_cnt = (user >> 1);
        sof = user&1;
    }
};

// Partial specialization for bool
template <>
struct UserField<bool> {
    static void set(bool &user, uint32_t, bool sof) {
        user = sof;
    }
    static void get(const bool user, uint32_t& frame_cnt, bool& sof) {
        frame_cnt = 0; //always 0
        sof = user;
    }
};
}
template <typename T>
void set_SOF(T& user, uint32_t frame_cnt, bool sof) {
    UserField<T>::set(user, frame_cnt,sof);
}

template <typename T>
void get_SOF(const T user, uint32_t& frame_cnt, bool& sof) {
    UserField<T>::get(user, frame_cnt,sof);
}


template <
    typename pixel_pkg_t,
    int FRAME_W,
    typename stream_t>
void matrix_to_axis(stream_t &stream_o,
                    volatile uint32_t *y_bram,
                    int last_row,
                    uint32_t frame_cnt ,
                    bool en_SOF )
{
    // Format: pixel0 | pixel1 | pixel2 | pixel3
    static constexpr int BRAM_W = FRAME_W/4; 
    uint32_t offset = 0;
    for (int i = 0; i < last_row; ++i)
    {

        offset = i * BRAM_W;
        for (int j = 0; j < BRAM_W; ++j)
        {
            pixel_pkg_t px;
            px.data = y_bram[offset++];
            px.keep = -1; // All bytes valid
            px.strb = -1;
            px.id = 0;
            px.dest = 0;
            px.last = (j == BRAM_W - 1) ? 1 : 0;            // End of each line
            //px.user = en_SOF && (i == 0 && j == 0) ? 1 : 0; // Start of frame only
            bool sof = en_SOF && ((i == 0 && j == 0) ? 1 : 0); // Start of frame only
            set_SOF(px.user, frame_cnt, sof);
            stream_o.write(px);
        }
    }
}

template <
    typename pixel_pkg_t,
    int BRAM_W,
    typename stream_t>
void matrix_to_axis_unaligned(stream_t &stream_o,
                    volatile uint32_t *y_bram,
                    int last_row,
                    uint32_t frame_cnt ,
                    bool en_SOF )
{
    uint32_t offset = 0;
    uint32_t data_cache[3];
    bool sof;
    for (int i = 0; i < last_row; ++i)
    {

        //offset = i * BRAM_W;
        int j = 0; 
        while(j < BRAM_W)
        {
            pixel_pkg_t px;
            //read 3 consecutive double words
            data_cache[0] = y_bram[offset++];
            data_cache[1] = y_bram[offset++];
            data_cache[2] = y_bram[offset++];
            //send 1'st double word
                {
                    px.data = data_cache[0]>>8;
                    px.data &=0xFFFFFF;
                    px.keep = -1; // All bytes valid
                    px.strb = -1;
                    px.id = 0;
                    px.dest = 0;
                    px.last = (j == BRAM_W - 1) ? 1 : 0;            // End of each line
                    sof = en_SOF && (i == 0 && j == 0) ; // Start of frame only
                    set_SOF(px.user, frame_cnt, sof);
                    stream_o.write(px);
                    j++;
                }
            //send 2'nd double word    
                {
                    px.data = ((data_cache[0]&0xFF)<<16)|(data_cache[1]>>16);
                    px.data &=0xFFFFFF;
                    px.keep = -1; // All bytes valid
                    px.strb = -1;
                    px.id = 0;
                    px.dest = 0;
                    px.last = (j == BRAM_W - 1) ? 1 : 0;            // End of each line
                    stream_o.write(px);
                    j++;
                }
            //send 3'rd double word   
                {    
                    px.data = ((data_cache[1]&0xFFFF)<<8)|(data_cache[2]>>24);
                    px.data &=0xFFFFFF;
                    px.keep = -1; // All bytes valid
                    px.strb = -1;
                    px.id = 0;
                    px.dest = 0;
                    px.last = (j == BRAM_W - 1) ? 1 : 0;            // End of each line
                    stream_o.write(px);
                    j++;
                }
            //send 4'th double word 
                {
                    px.data =data_cache[2]& 0xFFFFFF;
                    px.keep = -1; // All bytes valid
                    px.strb = -1;
                    px.id = 0;
                    px.dest = 0;
                    px.last = (j == BRAM_W - 1) ? 1 : 0;            // End of each line
                    stream_o.write(px);
                    j++;
                }
        }; //while(j < BRAM_W)
    } //for (int i = 0; i < last_row; ++i)  
}

// === crop frame

// === input stream ===
static constexpr int STREAM_H_I = 260;
//static constexpr int STREAM_W_I = 360;
// === output stream ===
// static constexpr int VGA_H = 480;
// static constexpr int VGA_W = 640;
static constexpr int VGA_H = 224;
static constexpr int VGA_W = 224;


template <
    typename pixel_pkg_t,
    int BRAM_W,
    typename stream_t>
void vga_to_axis(stream_t &stream_o,
                 volatile uint32_t *y_bram,
                 int last_row)
{
    static constexpr int j_start = (BRAM_W - VGA_W) / 2;
    static constexpr int j_end = j_start + VGA_W;
    static_assert(j_end < BRAM_W, "Crop not possible allong y axis");
    static constexpr int top_row = (STREAM_H_I-VGA_H)/2;
    static constexpr int bottom_row = top_row + VGA_H - 1;
    static int row_out = 0;
    uint32_t offset = 0;

    for (int i = 0; i < last_row; ++i)
    {
        row_out++;
        if (row_out < top_row || row_out > bottom_row)
        {
            if (row_out == STREAM_H_I-1)
                row_out = 0;
            continue;
        }
        
        offset = i * BRAM_W + j_start;

        for (int j = 0; j < VGA_W; j += 4)
        {

            uint32_t p3 = y_bram[offset++] & 0xFF;
            uint32_t p2 = y_bram[offset++] & 0xFF;
            uint32_t p1 = y_bram[offset++] & 0xFF;
            uint32_t p0 = y_bram[offset++] & 0xFF;

            uint32_t packed = (p3 << 24) | (p2 << 16) | (p1 << 8) | p0;
            pixel_pkg_t px;
            px.data = packed;
            px.keep = -1; // All bytes valid
            px.strb = -1;
            px.id = 0;
            px.dest = 0;
            px.last = (j == VGA_W - 4) ? 1 : 0; // End of each line
            // if(px.last) std::cerr<<"*** end of line\n\n";
            px.user = (row_out == top_row && j == 0) ? 1 : 0; // Start of frame only
            // if(px.user) std::cerr<<"*** start of frame\n\n";
            stream_o.write(px);
        }
    }
}
// === axis to matrix ===
template <
    int ELEMS_MAX,
    typename stream_t,
    typename pixel_pkg_t>
void axis_read_frame(stream_t &stream_i, pixel_pkg_t &px_in_q, volatile uint32_t *x_bram, int &row_q, int &col_q)
{

    // === Read one frame ===
    int row = 0, col = 0;
    bool frame_started = false;
    uint32_t offset = 0;
    while (offset < ELEMS_MAX)
    {

        
        bool sof = 0;
        uint32_t frame_cnt=0;
        get_SOF(px_in_q.user,frame_cnt,sof);
        pixel_pkg_t px_in =  sof ? px_in_q : stream_i.read();
        get_SOF(px_in.user,frame_cnt,sof);
        // === Detect start of frame
        if (sof == 1 && !frame_started)
        {

            frame_started = true;
            // std::cerr<<"@ offset="<<offset<<"/ "<<stream_i.size()<<", frame_started:"<<frame_started<<"\n";
            sof =0;
            //set_SOF(px.user, frame_cnt, sof);
            set_SOF(px_in_q.user, frame_cnt, sof);
           
        }

        if (!frame_started)
            continue;
        if (sof == 1)
        {
            px_in_q = px_in;
            frame_started = false;
            break; // End of frame
        }
        
        uint8_t pixel0 = (px_in.data >> 24) & 0xFF;
        uint8_t pixel1 = (px_in.data >> 16) & 0xFF;
        uint8_t pixel2 = (px_in.data >> 8) & 0xFF;
        uint8_t pixel3 = (px_in.data) & 0xFF;

        x_bram[offset++] = pixel0;
        x_bram[offset++] = pixel1;
        x_bram[offset++] = pixel2;
        x_bram[offset++] = pixel3;

        // === Update coordinates ===
        col+=4;
        if (px_in.last == 1)
        {

            row++;
            col_q = col;
            col = 0;
        }
    }
    row_q = row;
    // std::cerr<<"@ offset="<<offset<<", frame_started:"<<frame_started<<", ";
    // std::cerr<<"offset < ELEMS_MAX: "<<(offset < ELEMS_MAX)<<"\n";
}
