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

    /// Seeds standard household appliances matching Sri Lankan household profiles and coursework specifications
    @discardableResult
    public func seedDefaultHouseholdAppliances(context: ModelContext) throws -> [Appliance] {
        let defaults: [(name: String, brand: String?, category: String, powerW: Int, qty: Int, hours: Double, mode: String, days: Int?)] = [
            ("Air Conditioner", "Inverter AC", "Cooling", 1200, 1, 6.0, "All day", nil),
            ("Refrigerator", "Double Door", "Refrigeration", 150, 1, 24.0, "All day", nil),
            ("Ceiling Fans", "KDK", "Ventilation", 75, 3, 8.0, "All day", nil),
            ("LED Lighting", "Philips", "Lighting", 15, 6, 5.0, "All day", nil),
            ("Smart TV", "Samsung", "Entertainment", 100, 1, 4.0, "All day", nil),
            ("Washing Machine", "LG", "Cleaning", 500, 1, 2.0, "Weekly", 3)
        ]
        
        var created: [Appliance] = []
        for def in defaults {
            let app = Appliance(
                name: def.name,
                brand: def.brand,
                category: def.category,
                powerW: def.powerW,
                quantity: def.qty,
                hoursPerDay: def.hours,
                usageMode: def.mode,
                daysPerWeek: def.days
            )
            context.insert(app)
            created.append(app)
        }
        
        try context.save()
        return created
    }
    
    /// Seeds default appliances only if the database has none
    public func seedIfNeeded(context: ModelContext) throws {
        let existing = try fetchAppliances(context: context)
        if existing.isEmpty {
            try seedDefaultHouseholdAppliances(context: context)
        }
    }
}
