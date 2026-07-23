#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int rows;
    int cols;
    double** data;
} Matrix;

Matrix* matrix_create(int rows, int cols) {
    Matrix* mat = malloc(sizeof(Matrix));
    mat->rows = rows;
    mat->cols = cols;
    mat->data = malloc(rows * sizeof(double*));

    for (int i = 0; i < rows; i++) {
        mat->data[i] = calloc(cols, sizeof(double));
    }

    return mat;
}

void matrix_destroy(Matrix* mat) {
    for (int i = 0; i < mat->rows; i++) {
        free(mat->data[i]);
    }
    free(mat->data);
    free(mat);
}

Matrix* matrix_add(Matrix* a, Matrix* b) {
    if (a->rows != b->rows || a->cols != b->cols) {
        return NULL;
    }

    Matrix* result = matrix_create(a->rows, a->cols);

    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            result->data[i][j] = a->data[i][j] + b->data[i][j];
        }
    }

    return result;
}

Matrix* matrix_multiply(Matrix* a, Matrix* b) {
    if (a->cols != b->rows) {
        return NULL;
    }

    Matrix* result = matrix_create(a->rows, b->cols);

    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < b->cols; j++) {
            for (int k = 0; k < a->cols; k++) {
                result->data[i][j] += a->data[i][j] * b->data[k][j];
            }
        }
    }

    return result;
}

Matrix* matrix_transpose(Matrix* mat) {
    Matrix* result = matrix_create(mat->cols, mat->rows);

    for (int i = 0; i < mat->rows; i++) {
        for (int j = 0; j < mat->cols; j++) {
            result->data[j][i] = mat->data[i][j];
        }
    }

    return result;
}

void matrix_scale(Matrix* mat, double scalar) {
    for (int i = 0; i < mat->rows; i++) {
        for (int j = 0; j < mat->cols; j++) {
            mat->data[i][j] *= scalar;
        }
    }
}

void matrix_print(Matrix* mat) {
    for (int i = 0; i < mat->rows; i++) {
        for (int j = 0; j < mat->cols; j++) {
            printf("%.2f ", mat->data[i][j]);
        }
        printf("\n");
    }
}
