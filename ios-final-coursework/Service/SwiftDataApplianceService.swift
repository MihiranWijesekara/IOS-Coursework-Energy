//import Foundation
//import SwiftData
//import CryptoKit
//
//public final class SwiftDataApplianceService {
//    public static let shared = SwiftDataApplianceService()
//
//    private init() {}
//
//
//
//
//    public func createAppliance(
//        context: ModelContext,
//        name: String,
//        category: String,
//        powerRating: Double,
//        usageHours: Double,
//        daysPerWeek: Int    
//        
//
//    ) throws -> User {
//        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
//        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
//        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        let user = User(
//            firstName: trimmedFirst,
//            lastName: trimmedLast,
//            email: trimmedEmail,
//            phone: phone?.isEmpty == true ? nil : phone,
//            province: province?.isEmpty == true ? nil : province,
//            district: district?.isEmpty == true ? nil : district,
//            town: town?.isEmpty == true ? nil : town,
//            passwordHash: hashPassword(password)
//        )
//
//        context.insert(user)
//        try context.save()
//        print("Saved:", user.firstName, user.lastName, user.email)
//        return user
//    }
//}
