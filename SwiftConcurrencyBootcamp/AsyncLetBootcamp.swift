//
//  AsyncLetBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 19.11.2024.
//

import SwiftUI

struct AsyncLetBootcamp: View {

    @State private var images: [UIImage] = []
    @State private var title: String = "Async Let Bootcamp"
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let url = URL(string: "https://picsum.photos/1000")!

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)

                    }
                }
            }
            .navigationTitle(title)
            .onAppear {
                //serialImageRequests()
                //parallelNotOptimalImageRequests()
                //parallelSingleTaskImageRequests()
                parallelSingleTaskImageAndStringRequests()
            }
        }
    }

    private func parallelSingleTaskImageAndStringRequests() {
        Task {
            do {
                async let fetchImage1 = fetchImage()
                async let fertchTitle1 = fetchTitle()

                let (image, title) = await (try fetchImage1, fertchTitle1)
                self.images.append(image)
                self.title = title
            } catch {

            }
        }
    }

    private func parallelSingleTaskImageRequests() {
        Task {
            do {
                async let fetchImage1 = fetchImage()
                async let fetchImage2 = fetchImage()
                async let fetchImage3 = fetchImage()
                async let fetchImage4 = fetchImage()

                // if one of fetch throws an error then we will go to catch part
                let (image1, image2, image3, image4) = await (try fetchImage1, try fetchImage2, try fetchImage3, try fetchImage4)
                self.images.append(contentsOf: [image1, image2, image3, image4])
            } catch {

            }
        }
    }

    private func parallelNotOptimalImageRequests() {
        Task {
            do {
                let image1 = try await fetchImage()
                self.images.append(image1)
            } catch {

            }
        }
        Task {
            do {
                let image2 = try await fetchImage()
                self.images.append(image2)
            } catch {

            }
        }
        Task {
            do {
                let image3 = try await fetchImage()
                self.images.append(image3)
            } catch {

            }
        }
        Task {
            do {
                let image4 = try await fetchImage()
                self.images.append(image4)
            } catch {

            }
        }
    }

    private func serialImageRequests() {
        Task {
            do {
                let image1 = try await fetchImage()
                self.images.append(image1)

                let image2 = try await fetchImage()
                self.images.append(image2)

                let image3 = try await fetchImage()
                self.images.append(image3)

                let image4 = try await fetchImage()
                self.images.append(image4)
            } catch {

            }
        }
    }

    private func fetchTitle() async -> String {
        return "NewTitle"
    }

    private func fetchImage() async throws -> UIImage {
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

#Preview {
    AsyncLetBootcamp()
}
