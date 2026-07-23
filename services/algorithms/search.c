#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int linear_search(int arr[], int n, int target) {
    for (int i = 0; i < n; i++) {
        if (arr[i] == target) {
            return i;
        }
    }
    return -1;
}

int binary_search(int arr[], int n, int target) {
    int left = 0;
    int right = n - 1;

    while (left <= right) {
        int mid = left + (right - left) / 2;

        if (arr[mid] == target) {
            return mid;
        }

        if (arr[mid] < target) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }

    return -1;
}

int binary_search_recursive(int arr[], int left, int right, int target) {
    if (left > right) {
        return -1;
    }

    int mid = left + (right - left) / 2;

    if (arr[mid] == target) {
        return mid;
    }

    if (arr[mid] < target) {
        return binary_search_recursive(arr, mid + 1, right, target);
    }

    return binary_search_recursive(arr, left, mid - 1, target);
}

int exponential_search(int arr[], int n, int target) {
    if (arr[0] == target) {
        return 0;
    }

    int i = 1;
    while (i < n && arr[i] <= target) {
        i *= 2;
    }

    int left = i / 2;
    int right = (i < n) ? i : n - 1;

    return binary_search_recursive(arr, left, right, target);
}

int interpolation_search(int arr[], int n, int target) {
    int left = 0;
    int right = n - 1;

    while (left <= right && target >= arr[left] && target <= arr[right]) {
        if (left == right) {
            if (arr[left] == target) return left;
            return -1;
        }

        int pos = left + ((target - arr[left]) * (right - left)) /
                         (arr[right] - arr[left]);

        if (arr[pos] == target) {
            return pos;
        }

        if (arr[pos] < target) {
            left = pos + 1;
        } else {
            right = pos - 1;
        }
    }

    return -1;
}

int jump_search(int arr[], int n, int target) {
    int step = (int)sqrt(n);
    int prev = 0;

    while (arr[(step < n ? step : n) - 1] < target) {
        prev = step;
        step += (int)sqrt(n);
        if (prev >= n) {
            return -1;
        }
    }

    while (arr[prev] < target) {
        prev++;
        if (prev == (step < n ? step : n)) {
            return -1;
        }
    }

    if (arr[prev] == target) {
        return prev;
    }

    return -1;
}

int ternary_search(int arr[], int left, int right, int target) {
    if (right >= left) {
        int mid1 = left + (right - left) / 3;
        int mid2 = right - (right - left) / 3;

        if (arr[mid1] == target) {
            return mid1;
        }
        if (arr[mid2] == target) {
            return mid2;
        }

        if (target < arr[mid1]) {
            return ternary_search(arr, left, mid1 - 1, target);
        } else if (target > arr[mid2]) {
            return ternary_search(arr, mid2 + 1, right, target);
        } else {
            return ternary_search(arr, mid1 + 1, mid2 - 1, target);
        }
    }

    return -1;
}

int* kmp_search(char* text, char* pattern, int* count) {
    int n = strlen(text);
    int m = strlen(pattern);

    int* lps = (int*)calloc(m, sizeof(int));
    int* result = (int*)malloc(n * sizeof(int));
    *count = 0;

    int len = 0;
    int i = 1;

    while (i < m) {
        if (pattern[i] == pattern[len]) {
            len++;
            lps[i] = len;
            i++;
        } else {
            if (len != 0) {
                len = lps[len - 1];
            } else {
                lps[i] = 0;
                i++;
            }
        }
    }

    i = 0;
    int j = 0;

    while (i < n) {
        if (pattern[j] == text[i]) {
            i++;
            j++;
        }

        if (j == m) {
            result[*count] = i - j;
            (*count)++;
            j = lps[j - 1];
        } else if (i < n && pattern[j] != text[i]) {
            if (j != 0) {
                j = lps[j - 1];
            } else {
                i++;
            }
        }
    }

    free(lps);
    return result;
}
