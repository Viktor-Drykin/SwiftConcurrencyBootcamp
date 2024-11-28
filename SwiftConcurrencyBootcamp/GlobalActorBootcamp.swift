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
        let data = await manager.getDataFromDatabase()
        await MainActor.run {
            self.dataArray = data
        }
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
        }
    }
}

#Preview {
    GlobalActorBootcamp()
}
