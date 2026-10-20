import Foundation
import SwiftData
import CryptoKit

public final class SwiftDataUserService {
    public static let shared = SwiftDataUserService()

    private init() {}

    public func hashPassword(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func findUser(context: ModelContext, email: String) -> User? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.email == trimmedEmail
            }
        )

        do {
            let users = try context.fetch(descriptor)
            if let match = users.first {
                return match
            }

            let allUsers = try context.fetch(FetchDescriptor<User>())
            return allUsers.first { user in
                user.email.lowercased() == trimmedEmail.lowercased()
            }
        } catch {
            print("SwiftData fetch user error: \(error)")
            return nil
        }
    }

    public func userExists(context: ModelContext, email: String) -> Bool {
        findUser(context: context, email: email) != nil
    }

    public func login(context: ModelContext, email: String, password: String) -> User? {
        guard let user = findUser(context: context, email: email) else { return nil }
        return user.passwordHash == hashPassword(password) ? user : nil
    }

    public func createUser(
        context: ModelContext,
        firstName: String,
        lastName: String,
        email: String,
        phone: String?,
        province: String?,
        district: String?,
        town: String?,
        password: String
    ) throws -> User {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        let user = User(
            firstName: trimmedFirst,
            lastName: trimmedLast,
            email: trimmedEmail,
            phone: phone?.isEmpty == true ? nil : phone,
            province: province?.isEmpty == true ? nil : province,
            district: district?.isEmpty == true ? nil : district,
            town: town?.isEmpty == true ? nil : town,
            passwordHash: hashPassword(password)
        )

        context.insert(user)
        try context.save()
        print("Saved:", user.firstName, user.lastName, user.email)
        return user
    }
}
