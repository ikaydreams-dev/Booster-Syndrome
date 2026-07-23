#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
    int data;
    struct Node* next;
} Node;

typedef struct {
    Node* head;
    int size;
} LinkedList;

LinkedList* list_create() {
    LinkedList* list = malloc(sizeof(LinkedList));
    list->head = NULL;
    list->size = 0;
    return list;
}

void list_append(LinkedList* list, int value) {
    Node* new_node = malloc(sizeof(Node));
    new_node->data = value;
    new_node->next = NULL;

    if (list->head == NULL) {
        list->head = new_node;
    } else {
        Node* current = list->head;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = new_node;
    }

    list->size++;
}

void list_prepend(LinkedList* list, int value) {
    Node* new_node = malloc(sizeof(Node));
    new_node->data = value;
    new_node->next = list->head;
    list->head = new_node;
    list->size++;
}

int list_get(LinkedList* list, int index) {
    if (index < 0 || index >= list->size) {
        return -1;
    }

    Node* current = list->head;
    for (int i = 0; i < index; i++) {
        current = current->next;
    }

    return current->data;
}

int list_remove(LinkedList* list, int value) {
    if (list->head == NULL) return 0;

    if (list->head->data == value) {
        Node* temp = list->head;
        list->head = list->head->next;
        free(temp);
        list->size--;
        return 1;
    }

    Node* current = list->head;
    while (current->next != NULL && current->next->data != value) {
        current = current->next;
    }

    if (current->next != NULL) {
        Node* temp = current->next;
        current->next = current->next->next;
        free(temp);
        list->size--;
        return 1;
    }

    return 0;
}

void list_reverse(LinkedList* list) {
    Node* prev = NULL;
    Node* current = list->head;
    Node* next = NULL;

    while (current != NULL) {
        next = current->next;
        current->next = prev;
        prev = current;
        current = next;
    }

    list->head = prev;
}

int list_contains(LinkedList* list, int value) {
    Node* current = list->head;

    while (current != NULL) {
        if (current->data == value) {
            return 1;
        }
        current = current->next;
    }

    return 0;
}

void list_destroy(LinkedList* list) {
    Node* current = list->head;

    while (current != NULL) {
        Node* temp = current;
        current = current->next;
        free(temp);
    }

    free(list);
}

void list_print(LinkedList* list) {
    Node* current = list->head;

    printf("[");
    while (current != NULL) {
        printf("%d", current->data);
        if (current->next != NULL) {
            printf(", ");
        }
        current = current->next;
    }
    printf("]\n");
}
