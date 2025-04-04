import Foundation

actor OperationManager {
    private var mainQueue: [OperationExecutable?]
    private var nextCycleQueue: [OperationExecutable] = []  // ✅ Queue for next cycle
    private let queueSize: Int
    private var head: Int = 0
    private var tail: Int = 0
    private var operationScheduler: any OperationScheduling
    private let exceptionHandler: ExceptionHandler
    private let warningHandler: WarningHandler
    private var isPumping: Bool = false
    public private(set) var isRunning = false
    private var waitingContinuation: CheckedContinuation<Void, Never>?
    private var pumpCycleID: UInt = 1  // ✅ Tracks processing cycles

    init(queueSize: Int = 10_000, scheduler: any OperationScheduling = OperationScheduler(),
         exceptionHandler: ExceptionHandler = ExceptionHandlerActor(), warningHandler: WarningHandler = MTEWarningHandler()) {
        self.operationScheduler = scheduler
        self.queueSize = queueSize
        self.mainQueue = Array(repeating: nil, count: queueSize)
        self.exceptionHandler = exceptionHandler
        self.warningHandler = warningHandler
    }

#if DEBUG
    public func pump(times: Int = 1) async {
        for _ in 0..<times {
            // ✅ Ensure we wake up OM if it was waiting
            if let continuation = waitingContinuation {
                waitingContinuation = nil
                continuation.resume()
            }

            await processNextOperation()  // ✅ Only processes ONE operation per loop
        }
    }
    
    public func pump(retries: UInt, until: () async -> Bool) async -> UInt {
        var tries = retries
        
        while await !until() && tries > 0 {
            tries -= 1
            
            // ✅ Ensure `pump()` only runs if there are active operations
//            guard head != tail else {
//                print("⏳ Pump retry called, but queue is empty. Doing nothing.")
//                return retries - tries
//            }
            
            await pump()
        }
        
        return retries - tries
    }
#endif

    func addOperation(_ operation: any OperationExecutable) async -> Bool {
        let nextTail = (tail + 1) % queueSize

        if nextTail == head {
            print("⚠️ Queue full! Cannot add operation: \(operation.operationName)")
            return false
        }

        print("📌 Adding operation: \(operation.operationName) (Queue size: \(calculateQueueSize()))")
        
        if operation.lastProcessed == pumpCycleID {
            nextCycleQueue.append(operation)
        } else {
            mainQueue[tail] = operation
            tail = nextTail
        }
        
        if let continuation = waitingContinuation {
            print("🔄 Waking up OM!")
            waitingContinuation = nil
            continuation.resume()  // ✅ Wake up OM immediately
        } else {
            print("⚠️ OM was not waiting. This might be a bug.")
        }

        return true
    }
    
    func start() async {
        guard !isRunning || isPumping else { return }
        isRunning = true
        
        repeat {
            if head == tail && !isPumping {
                print("⏳ OM is waiting for new tasks...")
                await withCheckedContinuation { continuation in
                    waitingContinuation = continuation
                }
                print("✅ OM resumed!")
            }
            
            guard isRunning || isPumping else { break }
            await processNextOperation()
            
        } while isRunning || isPumping
        
        isRunning = false
        isPumping = false
        print("✅ OperationManager has stopped.")
    }

    private func processNextOperation() async {
        // ✅ If there are no more operations in the queue, check `nextCycleQueue`
        if head == tail {
            pumpCycleID += 1
            
            if !nextCycleQueue.isEmpty {
                print("📥 Moving operations from nextCycleQueue to mainQueue...")

                for operation in nextCycleQueue {
                    _ = await addOperation(operation)
                }
                nextCycleQueue.removeAll()

                print("✅ Next cycle operations transferred. Continuing execution.")
            } else {
                print("⏳ No operations left. Suspending OM...")
                return  // ✅ Suspend OM since nothing is left to execute
            }
        }

        guard head != tail else { return }  // ✅ Ensure there's work to do

        guard let operation = mainQueue[head] else {
            head = (head + 1) % queueSize  // ✅ Move head forward if empty
            return
        }

        print("🚀 Executing operation: \(operation.operationName) | State: \(operation.state)")

        // 🔥 PANIC CHECK: Ensure the operation isn’t reprocessed in the same pump cycle
        if operation.lastProcessed == pumpCycleID {
            fatalError("🔥 Operation \(operation.operationName) is being executed twice in the same pump cycle!")
        }

        mainQueue[head] = nil
        head = (head + 1) % queueSize  // ✅ Move head forward

        operation.startTime = ContinuousClock().now

        let result = await operation.execute()

        await self.processResult(operation, result)
    }
    private func processResult(_ operation: OperationExecutable, _ result: OperationState) async {
        operation.lastProcessed = pumpCycleID  // ✅ Track the correct cycle
        switch result {
            case .firstRun:
                print("🔄 OM Processing firstRun -> running")
                operation.state = .running
                _ = await operationScheduler.addOperation(operation)
                fallthrough
            
            case .running:
                 _ = await addOperation(operation)

        case let .unusualExecutionEvent(.exception(message)):
                let shouldResume = await exceptionHandler.handleException(operation, message: message)
                if shouldResume {
                    print("🔄 Resuming operation: \(operation.operationName)")
                    operation.state = .running
                    nextCycleQueue.append(operation)  // ✅ Now safely handled in addOperation()
                }

        case let .unusualExecutionEvent(.abort(message)):
            print("🏁 Operation \(operation.operationName) aborted execution. No further action.")
            
        case .completed:
            print("🏁 Operation \(operation.operationName) finished execution. No further action.")

        default:
            fatalError("🔥 Unknown Operation State: \(result)")
        }
    }

    func stopNow() async {
        isRunning = false
        
        // ✅ Wake up `OM` if it is suspended waiting for operations
        if let continuation = waitingContinuation {
            waitingContinuation = nil
            continuation.resume()
        }
        
        // ✅ Clear queue to ensure no further operations run
        head = tail
        mainQueue = Array(repeating: nil, count: queueSize)
        
        print("🚨 OperationManager stopped immediately.")
    }
    
    func calculateQueueSize() -> Int {
        return (tail >= head) ? (tail - head) : (queueSize - head + tail)
    }
}
