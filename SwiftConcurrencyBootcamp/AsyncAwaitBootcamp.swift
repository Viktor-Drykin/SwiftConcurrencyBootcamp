//
//  AsyncAwaitBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 15.11.2024.
//
import SwiftUI

class AsyncAwaitBootcampViewModel: ObservableObject {

    @Published var dataArray: [String] = []

    func addTitle1() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dataArray.append("Title1: \(Thread.current)")
        }
    }

    func addTitle2() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let title = "Title2: \(Thread.current)"
            DispatchQueue.main.async {
                self.dataArray.append(title)

                let title3 = "Title3: \(Thread.current)"
                self.dataArray.append(title3)
            }
        }
    }

    func addAuthor() async {
        let author1 = "Author1: \(Thread.current)"
        await MainActor.run {
            self.dataArray.append(author1)
        }

        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let author2 = "Author2: \(Thread.current)"
        await MainActor.run {
            self.dataArray.append(author2)
            let author3 = "Author3: \(Thread.current)"
            self.dataArray.append(author3)
        }
    }

}

struct AsyncAwaitBootcamp: View {

    @StateObject private var viewModel = AsyncAwaitBootcampViewModel()

    var body: some View {
        List {
            ForEach(viewModel.dataArray, id: \.self) { item in
                Text(item)
            }
        }
        .onAppear {
            Task {
                await viewModel.addAuthor()
                let finalText = "FINEL: \(Thread.current)"
                viewModel.dataArray.append(finalText)
            }
//            viewModel.addTitle1()
//            viewModel.addTitle2()
        }
    }
}

#Preview {
    AsyncAwaitBootcamp()
}
