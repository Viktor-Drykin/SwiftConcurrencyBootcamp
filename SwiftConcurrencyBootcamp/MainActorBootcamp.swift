//
//  MainActorBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 30.11.2024.
//

import SwiftUI

fileprivate class MyManager {
    func getData() async throws -> String {
        print(">>> MyManager Thread: \(Thread.current)")
        return "MyManager getData"
    }
}

fileprivate actor MyManagerActor {
    func getData() async throws -> String {
        print(">>> MyManagerActor Thread: \(Thread.current)")
        return "MyManagerActor getData"
    }
}

@MainActor
class MainActorBootcampViewModel: ObservableObject {
    private let myManager = MyManager()
    private let myManagerActor = MyManagerActor()

    @Published private(set) var myData: String = "Starting data"
    private var tasks: [Task<Void, Never>] = []

    func cancelTasks() {
        tasks.forEach { $0.cancel() }
        tasks = []
    }

    // 1
    // let task = Task { - Everything inside the task will be not on the main thread, warning with UI changes on background thread
//    >>> action start Thread:  main
//    >>> action start inside Task: number = 12, name = (null)
//    >>> MyManager Thread: number = 12, name = (null)
//    >>> MyManagerActor Thread: number = 12, name = (null)

    // 2
    //let task = Task { @MainActor in - Task inside will be on a main thread, set myData values will on main thread
//    >>> action start Thread:  main
//    >>> action start inside Task:  main
//    >>> MyManager Thread: number = 3, name = (null)
//    >>> MyManagerActor Thread: number = 3, name = (null)

    // 3
    //@MainActor func action() { - Task inside will be on a main thread, set myData values will on main thread, thread inside managers will be not main
//    >>> action start Thread:  main
//    >>> action start inside Task:  main
//    >>> MyManager Thread: number = 3, name = (null)
//    >>> MyManagerActor Thread: number = 3, name = (null)

    // 4
    // @MainActor @Published private(set) var myData: String - won't let build the app because setting myData values will be not on a main thread

    // 5
    // @MainActor class MainActorBootcampViewModel: - Task inside will be on a main thread, set myData values will on main thread, thread inside managers will be not main

    func action() {
        print(">>> action start Thread: \(Thread.current)")
        let task = Task {
            do {
                print(">>> action start inside Task Thread: \(Thread.current)")
                myData = try await myManager.getData()
                myData = try await myManagerActor.getData()
            } catch {
                print(">>> error: \(error)")
            }
        }
        tasks.append(task)
    }
}

struct MainActorBootcamp: View {

    @StateObject private var viewModel =  MainActorBootcampViewModel()

    var body: some View {
        Button(viewModel.myData) {
            viewModel.action()
        }
        .onDisappear {
            viewModel.cancelTasks()
        }
    }
}

#Preview {
    MainActorBootcamp()
}
