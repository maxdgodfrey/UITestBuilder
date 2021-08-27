//
//  LoginView.swift
//  TestHarness
//
//  Created by Max Godfrey on 1/08/21.
//

import Combine
import SwiftUI

struct LoginView: View {

    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        VStack {
            TextField("Username", text: $viewModel.userName).padding()
            SecureField("Password", text: $viewModel.password).padding()
            if let error = viewModel.error {
                Text(error)
                    .background(RoundedRectangle(cornerRadius: 4).background(Color.red))
            }
            Spacer()
            if !viewModel.isLoading {
                Button("Login") {
                    withAnimation {
                        viewModel.login()
                    }
                }
            } else {
                ProgressView("Logging you in")
            }
        }
        .disabled(viewModel.isLoading)
        .padding()
        .navigationTitle("Harness App")
    }
}

final class LoginViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var error: String?

    private let loginSubject = PassthroughSubject<Void, Never>()

    var loginSuccesfull: ((User) -> Void)? = nil

    var cancellables = Set<AnyCancellable>()

    init() {
        loginSubject
            .flatMap {
                API.live.loginWithUsernameAndPassword(self.userName, self.password)
            }
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.error = "Uh oh"
                }
            } receiveValue: { [weak self] user in
                self?.loginSuccesfull?(user)
            }
            .store(in: &cancellables)

    }

    func login() {
        isLoading = true
        loginSubject.send(())
    }

}

struct API {
    let loginWithUsernameAndPassword: (String, String) -> AnyPublisher<User, Error>

    static let live: Self = .init { username, _ in
        Just(User(username: username))
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
