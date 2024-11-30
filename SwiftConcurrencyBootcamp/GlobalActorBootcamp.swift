//
//  GlobalActorBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 28.11.2024.
//

import SwiftUI

@globalActor final class MyGlobalActor {
    static var shared = MyNewDataManager()
}

actor MyNewDataManager {

    func getDataFromDatabase() -> [String] {
        return ["One", "Two", "Three", "Four", "Five"]
    }
}

class GlobalActorBootcampViewModel: ObservableObject {

    @MainActor @Published var dataArray: [String] = []
    let manager = MyGlobalActor.shared


    @MyGlobalActor
    func getData() async {

        // HEAVY COMPLEX METHODS
        print(">>>> Thread 1 \(Thread.current)")
        let data = await manager.getDataFromDatabase()
        await MainActor.run {
            print(">>>> Thread 1 1 \(Thread.current)")
            self.dataArray = data
        }
    }

    @MainActor
    func getData2() async {
        print(">>>> Thread 2 \(Thread.current)")
    }

}

struct GlobalActorBootcamp: View {

    @StateObject private var viewModel = GlobalActorBootcampViewModel()

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
            await viewModel.getData()
            await viewModel.getData2()
        }
    }
}

#Preview {
    GlobalActorBootcamp()
}
