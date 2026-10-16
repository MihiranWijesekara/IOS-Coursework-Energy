//
//  AuthenticationService.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//


import Foundation
import LocalAuthentication
import Combine

public final class AuthenticationService: ObservableObject {
    @Published public var biometryType: LABiometryType = .none
    @Published public var biometryError: String?
    
    public init() {
        checkBiometrySupport()
    }
    
    public func checkBiometrySupport() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometryType = context.biometryType
        } else {
            biometryType = .none
        }
    }
    
    public func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        let reason = "Authenticate to access EnergyLens and protect your energy data."
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            // Simulator or hardware without biometrics enrolled: simulate smooth fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                completion(true)
            }
        }
    }
}
