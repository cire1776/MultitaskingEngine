//
//  circular_queue.c
//  SwiftBenchmarks
//
//  Created by Eric Russell on 3/3/25.
//

#include <stdio.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <pthread.h>

#define QUEUE_SIZE 1024  // Must be power of 2 for best performance

typedef struct {
    int buffer[QUEUE_SIZE];
    atomic_int head;
    atomic_int tail;
} CircularQueue;

// ✅ Initialize the queue
void initQueue(CircularQueue* q) {
    atomic_store(&q->head, 0);
    atomic_store(&q->tail, 0);
}

// ✅ Enqueue (Returns `true` on success, `false` if full)
bool enqueue(CircularQueue* q, int value) {
//    printf("🔄 Enqueue on Thread: %ld\n", pthread_self());

    int head = atomic_load(&q->head);
    int tail = atomic_load(&q->tail);
    if ((tail + 1) % QUEUE_SIZE == head) {
        return false; // Queue is full
    }
    q->buffer[tail] = value;
    atomic_store(&q->tail, (tail + 1) % QUEUE_SIZE);
    return true;
}

// ✅ Dequeue (Returns `true` on success, `false` if empty)
bool dequeue(CircularQueue* q, int* value) {
//    printf("🔄 Dequeue on Thread: %ld\n", pthread_self());
    int head = atomic_load(&q->head);
    int tail = atomic_load(&q->tail);
    if (head == tail) {
        return false; // Queue is empty
    }
    *value = q->buffer[head];
    atomic_store(&q->head, (head + 1) % QUEUE_SIZE);
    return true;
}
