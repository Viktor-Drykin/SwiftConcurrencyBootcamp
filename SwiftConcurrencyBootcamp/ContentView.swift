//
//  ContentView.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 14.11.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.green
                .ignoresSafeArea()
            AsyncAwaitBootcamp()
        }
    }
}

#Preview {
    ContentView()
}
