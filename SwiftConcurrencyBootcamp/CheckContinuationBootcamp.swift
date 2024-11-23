//
//  CheckContinuationBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 22.11.2024.
//

import SwiftUI

class CheckContinuationBootcampNetworkManager {
    func getData(url: URL) async throws -> Data {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            throw error
        }
    }

    func getDataWithContinuation(url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
            .resume()
        }
    }

    func getHeartImageFromCache(completion: @escaping (_ image: UIImage?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            completion(UIImage(systemName: "heart.fill"))
        }
    }

    func getHeartImageWithContinuation() async -> UIImage? {
        await withCheckedContinuation { [weak self] continuation in
            self?.getHeartImageFromCache(completion: { image in
                continuation.resume(returning: image)
            })
        }
    }
}

class CheckContinuationBootcampViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    private let networkManager = CheckContinuationBootcampNetworkManager()

    func getImage() async {
        guard let url = URL(string: "https://picsum.photos/1000") else { return }
        do {
            let data = try await networkManager.getData(url: url)
            await addImageIfNeeded(data: data)

            let dataWithContinuation = try await networkManager.getDataWithContinuation(url: url)
            await addImageIfNeeded(data: dataWithContinuation)

            let heartImageWithContinuation = await networkManager.getHeartImageWithContinuation()
            if let heartImageWithContinuation {
                images.append(heartImageWithContinuation)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func addImageIfNeeded(data: Data) async {
        if let image = UIImage(data: data) {
            await MainActor.run {
                self.images.append(image)
            }
        }
    }
}

struct CheckContinuationBootcamp: View {

    @StateObject private var viewModel = CheckContinuationBootcampViewModel()

    var body: some View {
        VStack {
            ForEach(viewModel.images, id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .task {
            await viewModel.getImage()
        }
    }
}

#Preview {
    CheckContinuationBootcamp()
}
