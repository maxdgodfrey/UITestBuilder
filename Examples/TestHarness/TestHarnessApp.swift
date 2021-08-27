//
//  TestHarnessApp.swift
//  TestHarness
//
//  Created by Max Godfrey on 3/06/21.
//

import SwiftUI

struct User {
    let username: String
}

@main
struct TestHarnessApp: App {

    @StateObject var rootViewModel = RootViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if let user = rootViewModel.user {
                    ContentView(user: user)
                } else {
                    LoginView(viewModel: rootViewModel.loginViewModel)
                }
            }
        }
    }
}

final class RootViewModel: ObservableObject {

    @Published var user: User?

    let loginViewModel: LoginViewModel

    init() {
        loginViewModel = LoginViewModel()
        loginViewModel.loginSuccesfull = { [weak self] user in
            self?.user = user
        }
    }
}
