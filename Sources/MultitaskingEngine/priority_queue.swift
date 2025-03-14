//
//  priority_queue.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/9/25.
//
actor PriorityQueue<Element: Comparable & Sendable> {
    private var heap: [Element] = []

    var isEmpty: Bool { heap.isEmpty }

    var count: Int { heap.count }

    // Return the smallest element without removing it
    func peekMin() -> Element? {
        return heap.first
    }

    // Insert a new element into the priority queue
    func push(_ value: Element) {
        heap.append(value)
        heapifyUp(from: heap.count - 1)
    }

    // Remove and return the smallest element (min) from the priority queue
    func popMin() -> Element? {
        guard !heap.isEmpty else { return nil }
        if heap.count == 1 {
            return heap.removeFirst()
        }
        // Swap the first (min) with the last, remove last (which was min), then heapify down
        let minValue = heap[0]
        heap[0] = heap.removeLast()
        heapifyDown(from: 0)
        return minValue
    }

    // Maintain heap property after insertion (bubble up the new element)
    private func heapifyUp(from index: Int) {
        var childIndex = index
        let childValue = heap[childIndex]
        var parentIndex = (childIndex - 1) / 2  // parent index in heap array
        while childIndex > 0 && heap[parentIndex] > childValue {
            // Swap child and parent to fix order
            heap[childIndex] = heap[parentIndex]
            heap[parentIndex] = childValue
            childIndex = parentIndex
            parentIndex = (childIndex - 1) / 2
        }
    }

    // Maintain heap property after removal (bubble down the element at index to correct position)
    private func heapifyDown(from index: Int) {
        var parentIndex = index
        let count = heap.count
        while true {
            let leftIndex = 2 * parentIndex + 1
            let rightIndex = 2 * parentIndex + 2
            var smallestIndex = parentIndex

            // Find the smallest among parent and children
            if leftIndex < count && heap[leftIndex] < heap[smallestIndex] {
                smallestIndex = leftIndex
            }
            if rightIndex < count && heap[rightIndex] < heap[smallestIndex] {
                smallestIndex = rightIndex
            }
            if smallestIndex == parentIndex {
                // Heap property satisfied (parent is smaller than both children)
                break
            }
            // Swap parent with the smaller child
            heap.swapAt(parentIndex, smallestIndex)
            parentIndex = smallestIndex
        }
    }
}
