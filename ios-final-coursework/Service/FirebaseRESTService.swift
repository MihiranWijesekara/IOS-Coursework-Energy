//
//  FirebaseRESTService.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-26.
//

import Foundation

public final class FirebaseRESTService {
    public static let shared = FirebaseRESTService()
    
    // Read from GoogleService-Info.plist (Bundle.main); fall back to the energylens-coursework project values.
    private let apiKey: String
    private let projectID: String
    
    /// ID token from the latest successful sign-up / sign-in; sent as a Bearer token to Firestore when available.
    private var idToken: String?
    
    private init() {
        var key = "AIzaSyD7gGR63ClFoweCzWNxsM6htjHpFbFVVg8"
        var project = "energylens-coursework"
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            if let k = plist["API_KEY"] as? String, !k.isEmpty { key = k }
            if let p = plist["PROJECT_ID"] as? String, !p.isEmpty { project = p }
        }
        self.apiKey = key
        self.projectID = project
    }
    
    // MARK: - Authentication (Firebase Auth REST)
    
    /// Creates a Firebase Auth account. Returns the new user's `localId`.
    @discardableResult
    public func signUp(email: String, password: String) async throws -> String {
        try await authRequest(endpoint: "accounts:signUp", email: email, password: password)
    }
    
    /// Signs in an existing Firebase Auth account. Returns the user's `localId`.
    @discardableResult
    public func signIn(email: String, password: String) async throws -> String {
        try await authRequest(endpoint: "accounts:signInWithPassword", email: email, password: password)
    }
    
    private func authRequest(endpoint: String, email: String, password: String) async throws -> String {
        guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/\(endpoint)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw Self.firebaseError(domain: "FirebaseAuthREST", data: json, fallback: "Authentication failed.")
        }
        
        if let token = json?["idToken"] as? String { idToken = token }
        return json?["localId"] as? String ?? ""
    }
    
    // MARK: - Firestore sync (REST PATCH)
    
    /// Upserts `users/{sanitizedEmail}`.
    @MainActor
    public func syncUserProfile(user: User) async throws {
        let fields: [String: Any] = [
            "firstName": Self.string(user.firstName),
            "lastName": Self.string(user.lastName),
            "email": Self.string(user.email),
            "phone": Self.string(user.phone ?? ""),
            "province": Self.string(user.province ?? ""),
            "district": Self.string(user.district ?? ""),
            "town": Self.string(user.town ?? ""),
            "updatedAt": Self.timestamp(Date())
        ]
        try await patchDocument(collection: "users", documentID: Self.sanitizedEmail(user.email), fields: fields)
    }
    
    /// Upserts `bills/{bill.id}`.
    @MainActor
    public func syncBill(bill: SavedBill) async throws {
        let fields: [String: Any] = [
            "userEmail": Self.string(bill.userEmail),
            "accountNumber": Self.string(bill.accountNumber),
            "customerName": Self.string(bill.customerName),
            "providerName": Self.string(bill.providerName),
            "billingMonth": Self.string(bill.billingMonth),
            "readingDate": Self.string(bill.readingDate),
            "dueDate": Self.string(bill.dueDate),
            "totalKWh": Self.double(bill.totalKWh),
            "monthlyBill": Self.double(bill.monthlyBill),
            "totalAmount": Self.double(bill.totalAmount),
            "currency": Self.string(bill.currency)
        ]
        try await patchDocument(collection: "bills", documentID: bill.id.uuidString, fields: fields)
    }
    
    /// Upserts `appliances/{appliance.id}`.
    @MainActor
    public func syncAppliance(appliance: Appliance, userEmail: String) async throws {
        let fields: [String: Any] = [
            "userEmail": Self.string(userEmail),
            "name": Self.string(appliance.name),
            "category": Self.string(appliance.category ?? ""),
            "powerW": Self.integer(appliance.powerW),
            "quantity": Self.integer(appliance.quantity),
            "hoursPerDay": Self.double(appliance.hoursPerDay),
            "usageMode": Self.string(appliance.usageMode),
            "estimatedMonthlyKwh": Self.double(appliance.estimatedMonthlyKwh)
        ]
        try await patchDocument(collection: "appliances", documentID: appliance.id.uuidString, fields: fields)
    }
    
    // MARK: - Helpers
    
    private func patchDocument(collection: String, documentID: String, fields: [String: Any]) async throws {
        let encodedID = documentID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? documentID
        let endpoint = "https://firestore.googleapis.com/v1/projects/\(projectID)/databases/(default)/documents/\(collection)/\(encodedID)"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let idToken {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["fields": fields])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw Self.firebaseError(domain: "FirestoreREST", data: json, fallback: "Firestore sync failed for \(collection)/\(documentID).")
        }
    }
    
    /// Firestore-safe document ID derived from an email address (e.g. "a.b@x.com" -> "a_b_at_x_com").
    private static func sanitizedEmail(_ email: String) -> String {
        let lowered = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var result = ""
        for ch in lowered {
            if ch == "@" {
                result += "_at_"
            } else if ch.isASCII && (ch.isLetter || ch.isNumber || ch == "-" || ch == "_") {
                result.append(ch)
            } else {
                result.append("_")
            }
        }
        return result.isEmpty ? "unknown" : result
    }
    
    private static func string(_ value: String) -> [String: Any] { ["stringValue": value] }
    private static func double(_ value: Double) -> [String: Any] { ["doubleValue": value.isFinite ? value : 0.0] }
    // Firestore REST encodes int64 values as strings.
    private static func integer(_ value: Int) -> [String: Any] { ["integerValue": String(value)] }
    private static func timestamp(_ date: Date) -> [String: Any] {
        ["timestampValue": ISO8601DateFormatter().string(from: date)]
    }
    
    private static func firebaseError(domain: String, data: [String: Any]?, fallback: String) -> NSError {
        let message = (data?["error"] as? [String: Any])?["message"] as? String ?? fallback
        return NSError(domain: domain, code: 400, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
