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
    
    /// True when Face ID / Touch ID hardware is present and enrolled.
    public func canUseBiometrics() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Evaluates biometrics. Completes with `false` immediately when biometrics are unavailable,
    /// or when evaluation fails / is cancelled, so callers can fall back to the passcode pad.
    public func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        let reason = "Authenticate to access EnergyLens and protect your energy data."
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                self.biometryError = error?.localizedDescription
                completion(false)
            }
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async {
                self.biometryError = success ? nil : evalError?.localizedDescription
                completion(success)
            }
        }
    }
}
