//
//  AsyncStreamBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 05.12.2024.
//

import SwiftUI

//If we cancel task with async stream it won't cancel GCD inside which pass data to the Stream
//New Data 1
//New Data 2
//New Data 3
//New Data 4
//task is cancelled
//New Data 5
//New Data 6
//New Data 7
//New Data 8
//New Data 9
//New Data 10

class AsyncStreamDataManager {
    func getFakeData(
        completion: @escaping (_ value: Int) -> Void,
        onFinish: @escaping (_ error: Error?) -> Void
    ) {
        let items: [Int] = [1,2,3,4,5,6,7,8,9,10]

        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                print("New Data \(item)")
                completion(item)
                if item == items.last {
                    onFinish(nil)
                }
            }
        }
    }

    func getAsyncStream() -> AsyncStream<Int> {
        AsyncStream(bufferingPolicy: .unbounded) { [weak self] continuation in
            self?.getFakeData(completion: { value in
                continuation.yield(value)
            }, onFinish: { error in
                continuation.finish()
            })
        }
    }

    func getAsyncThrowingStream() -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream(bufferingPolicy: .unbounded) { [weak self] continuation in
            self?.getFakeData(completion: { value in
                continuation.yield(value)
            }, onFinish: { error in
                continuation.finish(throwing: error)
            })
        }
    }
}

@MainActor
final class AsyncStreamViewModel: ObservableObject {
    let manager = AsyncStreamDataManager()
    @Published private(set) var currentNumber: Int = 0

    func onViewAppear() {
        //callFuncWithCompletion()
        //callTaskWithAsyncStream()
        callTaskWithAsyncThrowingStream()
    }

    func callFuncWithCompletion() {
        manager.getFakeData(completion: { [weak self] value in
            self?.currentNumber = value
        }, onFinish: { _ in })
    }

    func callTaskWithAsyncStream() {
        Task {
            for await value in manager.getAsyncStream() {
                currentNumber = value
            }
        }
    }

    func callTaskWithAsyncThrowingStream() {
        let task = Task {
            do {
                for try await value in manager.getAsyncThrowingStream().dropFirst(2) {
                    currentNumber = value
                }
            } catch {
                currentNumber = 666
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            task.cancel()
            print("task is cancelled")
        }
    }
}

struct AsyncStreamBootcamp: View {

    @StateObject private var viewModel = AsyncStreamViewModel()

    var body: some View {
        Text("\(viewModel.currentNumber)")
            .onAppear {
                viewModel.onViewAppear()
            }
    }
}

#Preview {
    AsyncStreamBootcamp()
}
