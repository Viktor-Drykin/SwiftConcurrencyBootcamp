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

    func getRandomData() -> String? {
        data.append(UUID().uuidString)
        print(">>> MyDataManager Thread \(Thread.current)")
        return data.randomElement()
    }
}

struct HomeView: View {

    let manager = MyDataManager.instance
    @State private var text: String = ""
    let timer = Timer.publish(every: 0.1, tolerance: nil, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.gray.opacity(0.8).ignoresSafeArea()

            Text(text)
                .font(.headline)
        }
        .onReceive(timer) { _ in
            DispatchQueue.global(qos: .background).async {
                if let data = manager.getRandomData() {
                    DispatchQueue.main.async {
                        self.text = data
                    }
                }
            }
         }
    }
}

struct BrowseView: View {

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
            DispatchQueue.global(qos: .default).async {
                if let data = manager.getRandomData() {
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
