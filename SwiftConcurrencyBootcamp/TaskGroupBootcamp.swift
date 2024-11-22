//
//  TaskGroupBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 22.11.2024.
//

import SwiftUI

class TaskGroupDataManager {

    private let imageURLString = "https://picsum.photos/1000"

    func fetchImagesWithAsyncLet() async throws -> [UIImage] {
        async let fetchImage1 = await fetchImage(urlString: imageURLString)
        async let fetchImage2 = await fetchImage(urlString: imageURLString)
        async let fetchImage3 = await fetchImage(urlString: imageURLString)
        async let fetchImage4 = await fetchImage(urlString: imageURLString)
        let (image1, image2, image3, image4) = await (try fetchImage1, try fetchImage2, try fetchImage3, try fetchImage4)
        return [image1, image2, image3, image4]
    }

    func fetchImagesWithTaskGroup() async throws -> [UIImage] {
        let urlStrings = Array.init(repeating: imageURLString, count: 5)
        return try await withThrowingTaskGroup(of: UIImage?.self) { group in
            var images: [UIImage] = []
            images.reserveCapacity(urlStrings.count)

            for urlString in urlStrings {
                group.addTask {
                    try? await self.fetchImage(urlString: urlString)
                }
            }

            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }

            return images
        }
    }

    private func fetchImage(urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            if let image = UIImage(data: data) {
                return image
            } else {
                throw URLError(.badURL)
            }
        } catch {
            throw error
        }
    }
}

class TaskGroupBootcampViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    private let manager = TaskGroupDataManager()

    func getImages() async {
//        if let images = try? await manager.fetchImagesWithAsyncLet() {
//            self.images.append(contentsOf: images)
//        }

        if let images = try? await manager.fetchImagesWithTaskGroup() {
            self.images.append(contentsOf: images)
        }
    }

}

struct TaskGroupBootcamp: View {

    @StateObject private var viewModel = TaskGroupBootcampViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)

                    }
                }
            }
            .navigationTitle("Task Group")
        }
        .task {
            await viewModel.getImages()
        }
    }
}

#Preview {
    TaskGroupBootcamp()
}
