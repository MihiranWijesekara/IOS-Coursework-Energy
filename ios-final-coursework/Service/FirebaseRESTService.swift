//
//  FirebaseRESTService.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-26.
//

import Foundation

public final class FirebaseRESTService {
    public static let shared = FirebaseRESTService()
    
    // Replace with your values from GoogleService-Info.plist or Firebase Console
    private let apiKey = "AIzaSyD7gGR63ClFoweCzWNxsM6htjHpFbFVVg8"
    private let projectID = "energylens-coursework"
    
    private init() {}
    
    // 1. Sign Up User into Firebase Authentication via REST
    public func signUp(email: String, password: String) async throws -> String {
        let endpoint = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
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
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "FirebaseAuthREST", code: 400, userInfo: [NSLocalizedDescriptionKey: "Registration failed."])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["localId"] as? String ?? UUID().uuidString
    }
    
    // 2. Sync Electricity Bill to Firestore Collection via REST
    public func syncBill(bill: SavedBill) async throws {
        let documentID = bill.id.uuidString
        let endpoint = "https://firestore.googleapis.com/v1/projects/\(projectID)/databases/(default)/documents/bills/\(documentID)"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        let fields: [String: [String: Any]] = [
            "accountNumber": ["stringValue": bill.accountNumber],
            "totalKWh": ["doubleValue": bill.totalKWh],
            "totalAmount": ["doubleValue": bill.totalAmount],
            "billingMonth": ["stringValue": bill.billingMonth],
            "provider": ["stringValue": bill.providerName]
        ]
        
        let payload: [String: Any] = ["fields": fields]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        _ = try await URLSession.shared.data(for: request)
    }
}
