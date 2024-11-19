//
//  TaskBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 18.11.2024.
//

import SwiftUI

class TaskBootcampViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var image2: UIImage? = nil

    private let fallbackImage = UIImage(systemName: "xmark.circle.fill")

    func fetchImage() async {
        do {
            guard let url = URL(string: "https://picsum.photos/1000") else {
                //self.image = fallbackImage
                return
            }
            print(">>> image1 request")
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            DispatchQueue.main.async {
                print(">>> image1 apply image")
                self.image = UIImage(data: data)
            }

        } catch {
            //self.image = fallbackImage
            print(">>> \(error.localizedDescription)")
        }
    }

    func fetchImage2() async {
        do {
            guard let url = URL(string: "https://picsum.photos/1000") else {
                //self.image2 = fallbackImage
                return
            }
            print(">>> image2 request")
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            DispatchQueue.main.async {
                print(">>> image2 apply image")
                self.image2 = UIImage(data: data)
            }
        } catch {
            //self.image2 = fallbackImage
            print(">>> \(error.localizedDescription)")
        }
    }

    func fetchImageWithSleep() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        do {
            guard let url = URL(string: "https://picsum.photos/1000") else {
                //self.image = fallbackImage
                return
            }
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            await MainActor.run {
                self.image = UIImage(data: data)
                print(">>> image returned successfully")
            }

        } catch {
            //self.image = fallbackImage
            print(">>> \(error.localizedDescription)")
        }
    }
}

struct TaskBootcamp: View {

    @StateObject private var viewModel = TaskBootcampViewModel()

    var body: some View {
        VStack(spacing: 40) {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            Divider()
            if let image = viewModel.image2 {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        // perform task before view appears, cancel task when view disappears
        .task {
            await viewModel.fetchImageWithSleep()
        }
//        .onAppear {
//            //loadImages()
//            //checkPriorities()
//            //checkSubtasks()
//            checkCancellingTask()
//        }
//        .onDisappear {
//            fetchImageTask?.cancel()
//        }
    }

    @State private var fetchImageTask: Task<(), Never>? = nil

    private func checkCancellingTask() {
        self.fetchImageTask = Task {
            print(">>> checkCancellingTask: \(Thread.current) : \(Task.currentPriority)")
            await viewModel.fetchImageWithSleep()
        }
    }

    private func checkSubtasks() {
        Task(priority: .low) {
            print(">>> userInitiated: \(Thread.current) : \(Task.currentPriority)")

            // without groups
            // inherit parent priority
            // we can set directly priority or use detached, but Apple asks not to do it
            Task.detached {
                print(">>> detached: \(Thread.current) : \(Task.currentPriority)")
            }
        }
    }

    private func checkPriorities() {
        Task(priority: .high) {
            //try? await Task.sleep(nanoseconds: 2_000_000_000)
            await Task.yield()
            print(">>> high: \(Thread.current) : \(Task.currentPriority)")
        }
        Task(priority: .userInitiated) {
            print(">>> userInitiated: \(Thread.current) : \(Task.currentPriority)")
        }
        Task(priority: .medium) {
            print(">>> medium: \(Thread.current) : \(Task.currentPriority)")
        }
        Task(priority: .low) {
            print(">>> Low: \(Thread.current) : \(Task.currentPriority)")
        }
        Task(priority: .utility) {
            print(">>> utility: \(Thread.current) : \(Task.currentPriority)")
        }
        Task(priority: .background) {
            print(">>> background: \(Thread.current) : \(Task.currentPriority)")
        }
    }

    private func loadImages() {
        print(">>> start task1")
        Task {
            print(">>> task1 thread:\(Thread.current)")
            print(">>> task1 currentPriority: \(Task.currentPriority)")
            await viewModel.fetchImage()
        }
        print(">>> start task2")
        Task {
            print(">>> task2 thread:\(Thread.current)")
            print(">>> task2 currentPriority: \(Task.currentPriority)")
            await viewModel.fetchImage2()
        }
        print(">>> end")
    }
}

struct TaskBootcampHomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink("Click me!") {
                    TaskBootcamp()
                }
            }
        }
    }
}

#Preview {
    TaskBootcamp()
}
