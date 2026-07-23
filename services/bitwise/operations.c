#include <stdio.h>
#include <stdint.h>

uint32_t set_bit(uint32_t num, int pos) {
    return num | (1 << pos);
}

uint32_t clear_bit(uint32_t num, int pos) {
    return num & ~(1 << pos);
}

uint32_t toggle_bit(uint32_t num, int pos) {
    return num ^ (1 << pos);
}

int check_bit(uint32_t num, int pos) {
    return (num >> pos) & 1;
}

int count_set_bits(uint32_t num) {
    int count = 0;
    while (num) {
        count += num & 1;
        num >>= 1;
    }
    return count;
}

int is_power_of_two(uint32_t num) {
    return num && !(num & (num - 1));
}

uint32_t reverse_bits(uint32_t num) {
    uint32_t result = 0;
    for (int i = 0; i < 32; i++) {
        result = (result << 1) | (num & 1);
        num >>= 1;
    }
    return result;
}

uint32_t swap_bits(uint32_t num, int pos1, int pos2) {
    int bit1 = (num >> pos1) & 1;
    int bit2 = (num >> pos2) & 1;

    if (bit1 != bit2) {
        num ^= (1 << pos1);
        num ^= (1 << pos2);
    }

    return num;
}

int find_first_set_bit(uint32_t num) {
    if (num == 0) return -1;

    int pos = 0;
    while ((num & 1) == 0) {
        num >>= 1;
        pos++;
    }
    return pos;
}

uint32_t rotate_left(uint32_t num, int shift) {
    shift %= 32;
    return (num << shift) | (num >> (32 - shift));
}

uint32_t rotate_right(uint32_t num, int shift) {
    shift %= 32;
    return (num >> shift) | (num << (32 - shift));
}
