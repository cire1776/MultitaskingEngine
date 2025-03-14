#include "circular_queue_bridge.h"

// ✅ Create a global CircularQueue instance
static CircularQueue queue;

void initQueueBridge() {
    initQueue(&queue);
}

bool enqueueBridge(int value) {
    return enqueue(&queue, value);
}

bool dequeueBridge(int* value) {
    return dequeue(&queue, value);
}
