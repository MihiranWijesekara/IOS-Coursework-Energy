import Foundation
import SwiftData

public final class SwiftDataApplianceService {
    public static let shared = SwiftDataApplianceService()

    private init() {}

    public func createAppliance(
        context: ModelContext,
        name: String,
        brand: String? = nil,
        category: String? = nil,
        powerW: Int,
        quantity: Int = 1,
        hoursPerDay: Double,
        usageMode: String = "All day",
        daysPerWeek: Int? = nil,
        user: User? = nil
    ) throws -> Appliance {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "ApplianceValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Appliance name is required."])
        }

        let normalizedMode = usageMode == "Weekly" ? "Weekly" : "All day"
        let normalizedDays: Int? = normalizedMode == "Weekly" ? max(1, min(7, daysPerWeek ?? 1)) : nil

        let appliance = Appliance(
            name: trimmedName,
            brand: brand?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : brand,
            category: category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : category,
            powerW: powerW,
            quantity: max(1, quantity),
            hoursPerDay: hoursPerDay,
            usageMode: normalizedMode,
            daysPerWeek: normalizedDays,
            user: user
        )

        context.insert(appliance)
        try context.save()
        print("Saved appliance: \(appliance.name)")
        return appliance
    }

    public func fetchAppliances(context: ModelContext) throws -> [Appliance] {
        let descriptor = FetchDescriptor<Appliance>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }

    public func fetchApplianceById(context: ModelContext, id: UUID) throws -> Appliance? {
        let predicate = #Predicate<Appliance> { appliance in
            appliance.id == id
        }
        let descriptor = FetchDescriptor<Appliance>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    public func updateAppliance(
        context: ModelContext,
        appliance: Appliance,
        name: String,
        brand: String? = nil,
        category: String? = nil,
        powerW: Int,
        quantity: Int = 1,
        hoursPerDay: Double,
        usageMode: String = "All day",
        daysPerWeek: Int? = nil
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "ApplianceValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Appliance name is required."])
        }

        appliance.name = trimmedName
        appliance.brand = brand?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : brand
        appliance.category = category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : category
        appliance.powerW = powerW
        appliance.quantity = max(1, quantity)
        appliance.hoursPerDay = hoursPerDay
        appliance.usageMode = usageMode == "Weekly" ? "Weekly" : "All day"
        appliance.daysPerWeek = appliance.usageMode == "Weekly" ? max(1, min(7, daysPerWeek ?? 1)) : nil

        try context.save()
    }

    public func deleteAppliance(context: ModelContext, appliance: Appliance) throws {
        context.delete(appliance)
        try context.save()
    }
}
