import Atomics

nonisolated(unsafe) var completedOperations: ManagedAtomic<Int> = ManagedAtomic(0)

