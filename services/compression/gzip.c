#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    unsigned char* data;
    size_t size;
    size_t capacity;
} Buffer;

Buffer* buffer_create(size_t capacity) {
    Buffer* buf = malloc(sizeof(Buffer));
    buf->data = malloc(capacity);
    buf->size = 0;
    buf->capacity = capacity;
    return buf;
}

void buffer_destroy(Buffer* buf) {
    if (buf) {
        free(buf->data);
        free(buf);
    }
}

void buffer_append(Buffer* buf, unsigned char byte) {
    if (buf->size >= buf->capacity) {
        buf->capacity *= 2;
        buf->data = realloc(buf->data, buf->capacity);
    }
    buf->data[buf->size++] = byte;
}

typedef struct {
    unsigned char* input;
    size_t input_size;
    size_t input_pos;
    Buffer* output;
} CompressContext;

CompressContext* compress_init(unsigned char* data, size_t size) {
    CompressContext* ctx = malloc(sizeof(CompressContext));
    ctx->input = data;
    ctx->input_size = size;
    ctx->input_pos = 0;
    ctx->output = buffer_create(size + 1024);
    return ctx;
}

void compress_destroy(CompressContext* ctx) {
    if (ctx) {
        buffer_destroy(ctx->output);
        free(ctx);
    }
}

unsigned char* rle_compress(unsigned char* data, size_t size, size_t* out_size) {
    if (size == 0) {
        *out_size = 0;
        return NULL;
    }

    Buffer* buf = buffer_create(size);

    size_t i = 0;
    while (i < size) {
        unsigned char current = data[i];
        size_t count = 1;

        while (i + count < size && data[i + count] == current && count < 255) {
            count++;
        }

        buffer_append(buf, (unsigned char)count);
        buffer_append(buf, current);

        i += count;
    }

    *out_size = buf->size;
    unsigned char* result = malloc(buf->size);
    memcpy(result, buf->data, buf->size);
    buffer_destroy(buf);

    return result;
}

unsigned char* rle_decompress(unsigned char* data, size_t size, size_t* out_size) {
    if (size == 0 || size % 2 != 0) {
        *out_size = 0;
        return NULL;
    }

    Buffer* buf = buffer_create(size * 4);

    for (size_t i = 0; i < size; i += 2) {
        unsigned char count = data[i];
        unsigned char value = data[i + 1];

        for (unsigned char j = 0; j < count; j++) {
            buffer_append(buf, value);
        }
    }

    *out_size = buf->size;
    unsigned char* result = malloc(buf->size);
    memcpy(result, buf->data, buf->size);
    buffer_destroy(buf);

    return result;
}

typedef struct LZ77Match {
    int offset;
    int length;
    unsigned char next;
} LZ77Match;

LZ77Match find_longest_match(unsigned char* data, size_t pos, size_t size, int window_size) {
    LZ77Match match = {0, 0, pos < size ? data[pos] : 0};

    int start = pos > window_size ? pos - window_size : 0;

    for (int i = start; i < (int)pos; i++) {
        int len = 0;
        while (pos + len < size && data[i + len] == data[pos + len] && len < 255) {
            len++;
        }

        if (len > match.length) {
            match.offset = pos - i;
            match.length = len;
            match.next = (pos + len < size) ? data[pos + len] : 0;
        }
    }

    return match;
}

unsigned char* lz77_compress(unsigned char* data, size_t size, size_t* out_size, int window_size) {
    Buffer* buf = buffer_create(size);
    size_t pos = 0;

    while (pos < size) {
        LZ77Match match = find_longest_match(data, pos, size, window_size);

        if (match.length > 2) {
            buffer_append(buf, 1);
            buffer_append(buf, (unsigned char)(match.offset >> 8));
            buffer_append(buf, (unsigned char)(match.offset & 0xFF));
            buffer_append(buf, (unsigned char)match.length);
            buffer_append(buf, match.next);
            pos += match.length + 1;
        } else {
            buffer_append(buf, 0);
            buffer_append(buf, data[pos]);
            pos++;
        }
    }

    *out_size = buf->size;
    unsigned char* result = malloc(buf->size);
    memcpy(result, buf->data, buf->size);
    buffer_destroy(buf);

    return result;
}
