#ifndef CIRCULAR_QUEUE_BRIDGE_H
#define CIRCULAR_QUEUE_BRIDGE_H

#include "circular_queue.h"

void initQueueBridge(void);
bool enqueueBridge(int value);
bool dequeueBridge(int* value);

#endif  // CIRCULAR_QUEUE_BRIDGE_H
