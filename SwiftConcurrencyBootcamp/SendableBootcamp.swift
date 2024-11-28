//
//  SendableBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by Viktor Drykin on 28.11.2024.
//

import SwiftUI

actor CurrentUserManager {

    func updateDatabase(userInfo: MyClassUserInfo) {

    }

}

struct MyUserIfno: Sendable {
    let name: String
}

final class MyClassUserInfo: @unchecked Sendable {
    let name: String
    private var surname: String // @unchecked Sendable is because of variable in a class
    let queue = DispatchQueue(label: "com.myApp.MyClassUSerInfo")

    init(name: String, surname: String) {
        self.name = name
        self.surname = surname
    }

    func update(surname: String) {
        queue.async {
            self.surname = surname
        }
    }
}

class SendableBootcampViewModel: ObservableObject {

    let manager = CurrentUserManager()

    func updateCurrentUserInfo() async {
        //let info: MyUserIfno = .init(name: "info")
        let info: MyClassUserInfo = .init(name: "info", surname: "info2")

        await manager.updateDatabase(userInfo: info)
    }
}

struct SendableBootcamp: View {

    @StateObject private var viewModel = SendableBootcampViewModel()

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .task {
                <#code#>
            }
    }
}

#Preview {
    SendableBootcamp()
}
