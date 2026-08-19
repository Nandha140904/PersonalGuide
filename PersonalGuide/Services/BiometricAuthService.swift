// MARK: - BiometricAuthService.swift
// PersonalGuide
//
// Biometric authentication service using Apple's LocalAuthentication framework (Face ID / Touch ID / Passcode).
// Provides privacy shield and auto-lock when switching apps.

import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
@Observable
final class BiometricAuthService {

    static let shared = BiometricAuthService()

    /// Whether biometric lock is enabled in user settings.
    var isBiometricLockEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "PG_BIOMETRIC_LOCK_ENABLED")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "PG_BIOMETRIC_LOCK_ENABLED")
        }
    }

    /// Whether the app is currently unlocked for this session.
    var isUnlocked: Bool = false

    /// The available biometric type on the current device (Face ID, Touch ID, or None).
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }

    // MARK: - Authentication

    func authenticate() async -> Bool {
        guard isBiometricLockEnabled else {
            isUnlocked = true
            return true
        }

        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Fallback: unlock if device has no passcode/biometrics set
            isUnlocked = true
            return true
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Personal Guide to access your documents and cases."
            )
            self.isUnlocked = success
            return success
        } catch {
            self.isUnlocked = false
            return false
        }
    }

    func lock() {
        if isBiometricLockEnabled {
            isUnlocked = false
        }
    }

    // MARK: - Biometric Type Enum

    enum BiometricType {
        case faceID
        case touchID
        case opticID
        case none

        var displayName: String {
            switch self {
            case .faceID:  return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none:    return "Passcode"
            }
        }

        var iconName: String {
            switch self {
            case .faceID:  return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            case .none:    return "lock.fill"
            }
        }
    }
}
