//
//  AsyncPublisherBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 29.11.2024.
//

import SwiftUI
import Combine

// We need async publisher to connect Combine and SwiftConcurrency

class AsyncPublisherDataManager {

    @Published var myData: [String] = []

    func addData() async {
        myData.append("One")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Two")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Three")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Four")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

class AsyncPublisherBootcampViewModel: ObservableObject {

    @MainActor @Published var dataArray: [String] = []
    var cancellables = Set<AnyCancellable>()
    let manager = AsyncPublisherDataManager()

    init() {
        addSubscribers()
        //addCombineSubscribers()

    }

    private func addSubscribers() {
        Task {
            await MainActor.run {
                self.dataArray = ["First"]
            }

            for await value in manager.$myData.values {
                await MainActor.run {
                    self.dataArray = value
                }
                // we need a break if we want to get out of infinite loop (it's because we don't know when myData publisher stops)
                break
            }

            // without break in for await loop we never reach this call
            await MainActor.run {
                self.dataArray = ["Second"]
            }
        }
    }

//    private func addCombineSubscribers() {
//        manager.$myData
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] dataArray in
//                self?.dataArray = dataArray
//            }
//            .store(in: &cancellables)
//    }

    func start() async {
        await manager.addData()
    }
}

struct AsyncPublisherBootcamp: View {

    @StateObject private var viewModel = AsyncPublisherBootcampViewModel()

    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.dataArray, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    AsyncPublisherBootcamp()
}
