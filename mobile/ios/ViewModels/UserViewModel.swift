import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func fetchUser(userId: String) {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.request(
            endpoint: "/users/\(userId)",
            method: .get
        ) { (result: Result<User, NetworkError>) in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let user):
                    self.user = user
                case .failure(let error):
                    self.errorMessage = self.handleError(error)
                }
            }
        }
    }

    func updateUser(userId: String, firstName: String, lastName: String) {
        isLoading = true

        let updateData = [
            "firstName": firstName,
            "lastName": lastName
        ]

        guard let jsonData = try? JSONEncoder().encode(updateData) else {
            errorMessage = "Invalid data"
            return
        }

        NetworkManager.shared.request(
            endpoint: "/users/\(userId)",
            method: .put,
            body: jsonData
        ) { (result: Result<User, NetworkError>) in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let user):
                    self.user = user
                case .failure(let error):
                    self.errorMessage = self.handleError(error)
                }
            }
        }
    }

    private func handleError(_ error: NetworkError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isEditing = false
    @Published var bio = ""
    @Published var phone = ""

    func loadProfile() {
        // Load profile logic
    }

    func saveProfile() {
        // Save profile logic
        isEditing = false
    }
}

struct UserProfile {
    var bio: String
    var phone: String
    var country: String
    var city: String
}
