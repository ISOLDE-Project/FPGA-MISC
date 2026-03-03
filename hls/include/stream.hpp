#pragma once
#include <queue>
#include <cstddef>
#include <cassert>
#include "shapes/shapes.inc"

#ifdef LINUX_APP
#include <iostream>
#endif
namespace isolde
{

    template <typename T>
    class stream
    {
    private:
        std::queue<T> q;
        size_t capacity;

        static constexpr size_t DEFAULT_CAPACITY = 4*HEIGHT_I * WIDTH_I+1; // Full HD pixels

    public:
        // Default constructor uses Full HD capacity
        stream() : capacity(DEFAULT_CAPACITY) {}

        // Optional: Constructor for custom capacity
        stream(size_t cap) : capacity(cap) {}

        void write(const T &val)
        {
            
            assert(q.size() < capacity && "Attempted write in a full queue");
            
            
                q.push(val);
            
        }

        T read() {
            assert(!q.empty() && "Attempted to read from an empty queue");
            T val = q.front();
            q.pop();
            return val;
        }

        bool empty() const { return q.empty(); }

        bool full() const { return q.size() >= capacity; }

        size_t size() const { return q.size(); }

        void clear()
        {
            while (!q.empty())
            {
                q.pop();
            }
        }
    };

}