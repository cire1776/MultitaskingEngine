#ifndef CIRCULAR_QUEUE_H
#define CIRCULAR_QUEUE_H

#include <stdatomic.h>
#include <stdbool.h>

#define QUEUE_SIZE 1024  // Must be power of 2

typedef struct {
    int buffer[QUEUE_SIZE];
    atomic_int head;
    atomic_int tail;
} CircularQueue;

// ✅ Function declarations for Swift interop
void initQueue(CircularQueue* q);
bool enqueue(CircularQueue* q, int value);
bool dequeue(CircularQueue* q, int* value);

#endif  // CIRCULAR_QUEUE_H
