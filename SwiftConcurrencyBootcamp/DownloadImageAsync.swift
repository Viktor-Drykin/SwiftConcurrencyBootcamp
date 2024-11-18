//
//  DownloadImageAsync.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 15.11.2024.
//

import SwiftUI
import Combine

class DownloadImageAsyncImageLoader {

    let url = URL(string: "https://picsum.photos/200")!

    private func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            (response.statusCode >= 200 && response.statusCode < 300)
        else {
            return nil
                }
        return image
    }

    func downloadWithEscaping(completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completion(image, error)
        }
        .resume()
    }

    func downloadWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError({ $0 })
            .eraseToAnyPublisher()
    }

    func downloadWithAsync() async throws -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
            return handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }

}

class DownloadImageAsyncViewModel: ObservableObject {
    
    @Published var escapingImage: UIImage? = nil
    @Published var combineImage: UIImage? = nil
    @Published var asyncAwaitImage: UIImage? = nil

    let loader = DownloadImageAsyncImageLoader()
    private let fallbackImage = UIImage(systemName: "xmark.circle.fill")
    var cancellables = Set<AnyCancellable>()

    func fetchImage() {
        loader.downloadWithEscaping { [weak self] image, error in
            DispatchQueue.main.async {
                if let image = image {
                    self?.escapingImage = image
                }
                if error != nil {
                    self?.escapingImage = self?.fallbackImage
                }
            }
        }
    }

    func fetchWithCombine() {
        loader.downloadWithCombine()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.combineImage = self?.fallbackImage
                }
            } receiveValue: { [weak self] image in
                self?.combineImage = image
            }
            .store(in: &cancellables)
    }

    func fetchWithAsyncAwait() async {
        do {
            let image = try await loader.downloadWithAsync()
            await MainActor.run {
                asyncAwaitImage = image
            }
        } catch {
            asyncAwaitImage = fallbackImage
        }
    }
}

struct DownloadImageAsync: View {

    @StateObject private var viewModel = DownloadImageAsyncViewModel()

    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                VStack {
                    makeImageIfExist(
                        image: viewModel.escapingImage,
                        color: Color.green
                    )
                    makeImageIfExist(
                        image: viewModel.combineImage,
                        color: Color.yellow
                    )
                    makeImageIfExist(image: viewModel.asyncAwaitImage, color: Color.blue)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            viewModel.fetchImage()
            viewModel.fetchWithCombine()
            Task {
                await viewModel.fetchWithAsyncAwait()
            }
        }
    }

    @ViewBuilder
    func makeImageIfExist(image: UIImage?, color: Color) -> some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .padding()
                .background(color)
        }
    }
}

#Preview {
    DownloadImageAsync()
}
