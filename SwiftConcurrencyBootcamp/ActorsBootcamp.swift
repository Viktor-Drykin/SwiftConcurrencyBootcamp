//
//  ActorsBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 28.11.2024.
//

import SwiftUI

// 1. What is the problem that actors are solving?
// 2. How was it solved prior to actors?
// 3. Actors can solve the problem!

class MyDataManager {
    static let instance = MyDataManager()

    private init() { }

    private var data: [String] = []
    private let lock = DispatchQueue(label: "com.MyApp.DataManager")

    func getRandomData(completion: @escaping (String?) -> Void) {
        lock.async {
            self.data.append(UUID().uuidString)
            print(">>> MyDataManager Thread \(Thread.current)")
            return completion(self.data.randomElement())
        }
    }
}

actor MyActorDataManager {
    static let instance = MyActorDataManager()

    private init() { }

    private var data: [String] = []

    func getRandomData() -> String? {
        self.data.append(UUID().uuidString)
        print(">>> MyActorDataManager Thread \(Thread.current)")
        return self.data.randomElement()
    }

    // nonisolated - we don't need this function to be isolated in actor scope
    nonisolated func getSavedData() -> String {
        return "new data"
    }
}

struct HomeView: View {

    let actorManager = MyActorDataManager.instance
    let manager = MyDataManager.instance
    @State private var text: String = ""
    let timer = Timer.publish(every: 0.1, tolerance: nil, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.gray.opacity(0.8).ignoresSafeArea()

            Text(text)
                .font(.headline)
        }
        .onAppear(perform: {
            var newString: String? = actorManager.getSavedData()
            Task {
                newString = await actorManager.getRandomData()
            }
        })
        .onReceive(timer) { _ in
            actorMethod()
            //            gcdMethod()
        }
    }

    private func actorMethod() {
        Task {
            if let data = await actorManager.getRandomData() {
                await MainActor.run {
                    self.text = data
                }
            }
        }
    }

    private func gcdMethod() {
        DispatchQueue.global(qos: .background).async {
            manager.getRandomData { data in
                if let data {
                    DispatchQueue.main.async {
                        self.text = data
                    }
                }
            }
        }
    }
}

struct BrowseView: View {

    let actorManager = MyActorDataManager.instance
    let manager = MyDataManager.instance
    @State private var text: String = ""
    let timer = Timer.publish(every: 0.1, tolerance: nil, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.yellow.opacity(0.8).ignoresSafeArea()

            Text(text)
                .font(.headline)
        }
        .onReceive(timer) { _ in
            //gcdMethod()
            actorMethod()
         }
    }

    private func actorMethod() {
        Task {
            if let data = await actorManager.getRandomData() {
                await MainActor.run {
                    self.text = data
                }
            }
        }
    }

    private func gcdMethod() {
        DispatchQueue.global(qos: .default).async {
            manager.getRandomData { data in
                if let data {
                    DispatchQueue.main.async {
                        self.text = data
                    }
                }
            }
        }
    }
}

struct ActorsBootcamp: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label {
                        Text("Home")
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
            BrowseView()
                .tabItem {
                    Label {
                        Text("Browse")
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                }
        }
    }
}

#Preview {
    ActorsBootcamp()
}
