#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <pthread.h>
#include "cache.h"

#define PORT 6380
#define BUFFER_SIZE 4096
#define MAX_CLIENTS 100

typedef struct {
    int socket;
    struct sockaddr_in address;
} Client;

Cache* global_cache;
pthread_mutex_t cache_mutex = PTHREAD_MUTEX_INITIALIZER;

void* handle_client(void* arg) {
    Client* client = (Client*)arg;
    char buffer[BUFFER_SIZE];
    int bytes_read;

    while ((bytes_read = recv(client->socket, buffer, BUFFER_SIZE - 1, 0)) > 0) {
        buffer[bytes_read] = '\0';

        char command[10], key[MAX_KEY_LENGTH], value[MAX_VALUE_LENGTH];
        int ttl = 3600;

        sscanf(buffer, "%s %s %s %d", command, key, value, &ttl);

        pthread_mutex_lock(&cache_mutex);

        if (strcmp(command, "SET") == 0) {
            cache_set(global_cache, key, value, ttl);
            send(client->socket, "+OK\r\n", 5, 0);
        }
        else if (strcmp(command, "GET") == 0) {
            char* result = cache_get(global_cache, key);
            if (result) {
                char response[BUFFER_SIZE];
                snprintf(response, BUFFER_SIZE, "$%ld\r\n%s\r\n", strlen(result), result);
                send(client->socket, response, strlen(response), 0);
            } else {
                send(client->socket, "$-1\r\n", 5, 0);
            }
        }
        else if (strcmp(command, "DELETE") == 0) {
            if (cache_delete(global_cache, key)) {
                send(client->socket, "+OK\r\n", 5, 0);
            } else {
                send(client->socket, "-NOT FOUND\r\n", 13, 0);
            }
        }
        else if (strcmp(command, "CLEAR") == 0) {
            cache_clear(global_cache);
            send(client->socket, "+OK\r\n", 5, 0);
        }
        else if (strcmp(command, "SIZE") == 0) {
            char response[50];
            snprintf(response, 50, ":%d\r\n", cache_size(global_cache));
            send(client->socket, response, strlen(response), 0);
        }

        pthread_mutex_unlock(&cache_mutex);
    }

    close(client->socket);
    free(client);
    return NULL;
}

int main() {
    int server_socket;
    struct sockaddr_in server_addr;

    global_cache = cache_create();

    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("Socket creation failed");
        return 1;
    }

    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        return 1;
    }

    if (listen(server_socket, MAX_CLIENTS) < 0) {
        perror("Listen failed");
        return 1;
    }

    printf("Cache server listening on port %d\n", PORT);

    while (1) {
        Client* client = malloc(sizeof(Client));
        socklen_t addr_len = sizeof(client->address);

        client->socket = accept(server_socket, (struct sockaddr*)&client->address, &addr_len);

        if (client->socket < 0) {
            free(client);
            continue;
        }

        pthread_t thread;
        pthread_create(&thread, NULL, handle_client, client);
        pthread_detach(thread);
    }

    cache_destroy(global_cache);
    close(server_socket);
    return 0;
}
