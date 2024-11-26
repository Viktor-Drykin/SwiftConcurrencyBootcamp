//
//  StructClassActor.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 23.11.2024.
//

import SwiftUI

/*
 Interesting Links:
 https://stackoverflow.com/questions/24232799/why-choose-struct-over-class/24232845
 https://www.backblaze.com/blog/whats-the-diff-programs-processes-and-threads/
 */

struct StructClassActor: View {
    var body: some View {
        Text("Hello, World!")
            .onAppear {
                runTest()
            }
    }
}

#Preview {
    StructClassActor()
}

actor MyActor {
    var title: String

    init(title: String) {
        self.title = title
    }

    func update(title: String) {
        self.title = title
    }
}

extension StructClassActor {

    private func runTest() {
        print("Test started")
        actorTest1()
    }

    private func actorTest1() {
        Task {
            print("---------Actor test 1----------")
            let objA = MyActor(title: "Starting title!")
            let objB = objA
            await print("Object A:", objA.title)
            await print("Object B:", objB.title)
            // Actor-isolated property 'title' can not be mutated from the main actor; this is an error in the Swift 6 language mode
            //objB.title = "New title"

            await objB.update(title: "New title")
            print("Title was changed for B")
            await print("Object A:", objA.title)
            await print("Object B:", objB.title)
        }
    }
}
