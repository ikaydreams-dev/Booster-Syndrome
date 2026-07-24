#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

void xor_encrypt_decrypt(uint8_t* data, size_t len, const uint8_t* key, size_t key_len) {
    for (size_t i = 0; i < len; i++) {
        data[i] ^= key[i % key_len];
    }
}

typedef struct {
    uint8_t key[256];
    uint8_t S[256];
    int i;
    int j;
} RC4Context;

void rc4_init(RC4Context* ctx, const uint8_t* key, size_t key_len) {
    for (int i = 0; i < 256; i++) {
        ctx->S[i] = i;
    }

    int j = 0;
    for (int i = 0; i < 256; i++) {
        j = (j + ctx->S[i] + key[i % key_len]) % 256;
        uint8_t temp = ctx->S[i];
        ctx->S[i] = ctx->S[j];
        ctx->S[j] = temp;
    }

    ctx->i = 0;
    ctx->j = 0;
}

void rc4_crypt(RC4Context* ctx, uint8_t* data, size_t len) {
    for (size_t k = 0; k < len; k++) {
        ctx->i = (ctx->i + 1) % 256;
        ctx->j = (ctx->j + ctx->S[ctx->i]) % 256;

        uint8_t temp = ctx->S[ctx->i];
        ctx->S[ctx->i] = ctx->S[ctx->j];
        ctx->S[ctx->j] = temp;

        uint8_t K = ctx->S[(ctx->S[ctx->i] + ctx->S[ctx->j]) % 256];
        data[k] ^= K;
    }
}

void caesar_cipher(char* text, int shift) {
    for (size_t i = 0; text[i] != '\0'; i++) {
        if (text[i] >= 'a' && text[i] <= 'z') {
            text[i] = ((text[i] - 'a' + shift) % 26) + 'a';
        } else if (text[i] >= 'A' && text[i] <= 'Z') {
            text[i] = ((text[i] - 'A' + shift) % 26) + 'A';
        }
    }
}

void vigenere_encrypt(const char* plaintext, const char* key, char* ciphertext) {
    size_t key_len = strlen(key);
    size_t text_len = strlen(plaintext);

    for (size_t i = 0; i < text_len; i++) {
        if (plaintext[i] >= 'a' && plaintext[i] <= 'z') {
            int shift = key[i % key_len] - 'a';
            ciphertext[i] = ((plaintext[i] - 'a' + shift) % 26) + 'a';
        } else if (plaintext[i] >= 'A' && plaintext[i] <= 'Z') {
            int shift = key[i % key_len] - 'A';
            ciphertext[i] = ((plaintext[i] - 'A' + shift) % 26) + 'A';
        } else {
            ciphertext[i] = plaintext[i];
        }
    }
    ciphertext[text_len] = '\0';
}

void vigenere_decrypt(const char* ciphertext, const char* key, char* plaintext) {
    size_t key_len = strlen(key);
    size_t text_len = strlen(ciphertext);

    for (size_t i = 0; i < text_len; i++) {
        if (ciphertext[i] >= 'a' && ciphertext[i] <= 'z') {
            int shift = key[i % key_len] - 'a';
            plaintext[i] = ((ciphertext[i] - 'a' - shift + 26) % 26) + 'a';
        } else if (ciphertext[i] >= 'A' && ciphertext[i] <= 'Z') {
            int shift = key[i % key_len] - 'A';
            plaintext[i] = ((ciphertext[i] - 'A' - shift + 26) % 26) + 'A';
        } else {
            plaintext[i] = ciphertext[i];
        }
    }
    plaintext[text_len] = '\0';
}

uint32_t hash_djb2(const char* str) {
    uint32_t hash = 5381;
    int c;

    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c;
    }

    return hash;
}

uint32_t hash_sdbm(const char* str) {
    uint32_t hash = 0;
    int c;

    while ((c = *str++)) {
        hash = c + (hash << 6) + (hash << 16) - hash;
    }

    return hash;
}

uint32_t hash_fnv1a(const char* str) {
    uint32_t hash = 2166136261u;

    while (*str) {
        hash ^= (uint8_t)*str++;
        hash *= 16777619u;
    }

    return hash;
}

typedef struct {
    uint32_t state[4];
    uint32_t count[2];
    uint8_t buffer[64];
} MD5Context;

#define F(x, y, z) (((x) & (y)) | ((~x) & (z)))
#define G(x, y, z) (((x) & (z)) | ((y) & (~z)))
#define H(x, y, z) ((x) ^ (y) ^ (z))
#define I(x, y, z) ((y) ^ ((x) | (~z)))

#define ROTATE_LEFT(x, n) (((x) << (n)) | ((x) >> (32-(n))))

void md5_transform(uint32_t state[4], const uint8_t block[64]) {
    uint32_t a = state[0], b = state[1], c = state[2], d = state[3];
    uint32_t x[16];

    for (int i = 0, j = 0; i < 16; i++, j += 4) {
        x[i] = (uint32_t)block[j] | ((uint32_t)block[j+1] << 8) |
               ((uint32_t)block[j+2] << 16) | ((uint32_t)block[j+3] << 24);
    }

    static const uint32_t T[64] = {
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    };

    state[0] = a;
    state[1] = b;
    state[2] = c;
    state[3] = d;
}

void base64_encode(const uint8_t* input, size_t len, char* output) {
    static const char encoding_table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    size_t i, j;

    for (i = 0, j = 0; i < len;) {
        uint32_t octet_a = i < len ? input[i++] : 0;
        uint32_t octet_b = i < len ? input[i++] : 0;
        uint32_t octet_c = i < len ? input[i++] : 0;

        uint32_t triple = (octet_a << 16) + (octet_b << 8) + octet_c;

        output[j++] = encoding_table[(triple >> 18) & 0x3F];
        output[j++] = encoding_table[(triple >> 12) & 0x3F];
        output[j++] = encoding_table[(triple >> 6) & 0x3F];
        output[j++] = encoding_table[triple & 0x3F];
    }

    int mod = len % 3;
    if (mod == 1) {
        output[j - 2] = '=';
        output[j - 1] = '=';
    } else if (mod == 2) {
        output[j - 1] = '=';
    }

    output[j] = '\0';
}

int base64_decode(const char* input, uint8_t* output) {
    static const uint8_t decoding_table[256] = {
        ['A'] = 0, ['B'] = 1, ['C'] = 2, ['D'] = 3, ['E'] = 4, ['F'] = 5,
        ['G'] = 6, ['H'] = 7, ['I'] = 8, ['J'] = 9, ['K'] = 10, ['L'] = 11,
        ['M'] = 12, ['N'] = 13, ['O'] = 14, ['P'] = 15, ['Q'] = 16, ['R'] = 17,
        ['S'] = 18, ['T'] = 19, ['U'] = 20, ['V'] = 21, ['W'] = 22, ['X'] = 23,
        ['Y'] = 24, ['Z'] = 25, ['a'] = 26, ['b'] = 27, ['c'] = 28, ['d'] = 29,
        ['e'] = 30, ['f'] = 31, ['g'] = 32, ['h'] = 33, ['i'] = 34, ['j'] = 35,
        ['k'] = 36, ['l'] = 37, ['m'] = 38, ['n'] = 39, ['o'] = 40, ['p'] = 41,
        ['q'] = 42, ['r'] = 43, ['s'] = 44, ['t'] = 45, ['u'] = 46, ['v'] = 47,
        ['w'] = 48, ['x'] = 49, ['y'] = 50, ['z'] = 51, ['0'] = 52, ['1'] = 53,
        ['2'] = 54, ['3'] = 55, ['4'] = 56, ['5'] = 57, ['6'] = 58, ['7'] = 59,
        ['8'] = 60, ['9'] = 61, ['+'] = 62, ['/'] = 63
    };

    size_t len = strlen(input);
    size_t i, j = 0;

    for (i = 0; i < len; i += 4) {
        uint32_t sextet_a = input[i] == '=' ? 0 : decoding_table[(uint8_t)input[i]];
        uint32_t sextet_b = input[i+1] == '=' ? 0 : decoding_table[(uint8_t)input[i+1]];
        uint32_t sextet_c = input[i+2] == '=' ? 0 : decoding_table[(uint8_t)input[i+2]];
        uint32_t sextet_d = input[i+3] == '=' ? 0 : decoding_table[(uint8_t)input[i+3]];

        uint32_t triple = (sextet_a << 18) + (sextet_b << 12) + (sextet_c << 6) + sextet_d;

        if (i + 2 < len && input[i+2] != '=') output[j++] = (triple >> 16) & 0xFF;
        if (i + 3 < len && input[i+3] != '=') output[j++] = (triple >> 8) & 0xFF;
        if (i + 4 < len) output[j++] = triple & 0xFF;
    }

    return j;
}

uint32_t crc32(const uint8_t* data, size_t len) {
    static uint32_t table[256];
    static int table_computed = 0;

    if (!table_computed) {
        for (uint32_t i = 0; i < 256; i++) {
            uint32_t c = i;
            for (int k = 0; k < 8; k++) {
                c = (c & 1) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
            }
            table[i] = c;
        }
        table_computed = 1;
    }

    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < len; i++) {
        crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8);
    }

    return crc ^ 0xFFFFFFFF;
}

void generate_random_bytes(uint8_t* buffer, size_t len) {
    srand(time(NULL));
    for (size_t i = 0; i < len; i++) {
        buffer[i] = rand() % 256;
    }
}
