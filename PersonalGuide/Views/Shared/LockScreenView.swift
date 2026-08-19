// MARK: - LockScreenView.swift
// PersonalGuide
//
// Privacy lock screen presenting biometric auth (Face ID / Touch ID / Passcode)
// to protect sensitive user documents and life admin cases.

import SwiftUI

struct LockScreenView: View {

    @Environment(BiometricAuthService.self) private var authService

    var body: some View {
        ZStack {
            Color.pgBackground
                .ignoresSafeArea()

            VStack(spacing: PGSpacing.xl) {
                Spacer()

                // App Brand Icon
                VStack(spacing: PGSpacing.md) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 64))
                        .foregroundStyle(.pgPrimary)

                    Text("Personal Guide")
                        .font(.pgHero)
                        .foregroundStyle(.pgTextPrimary)

                    Text("Your life administration, private & secure.")
                        .font(.pgBody)
                        .foregroundStyle(.pgTextSecondary)
                }

                Spacer()

                // Unlock Button
                Button {
                    Task {
                        _ = await authService.authenticate()
                    }
                } label: {
                    HStack(spacing: PGSpacing.sm) {
                        Image(systemName: authService.biometricType.iconName)
                            .font(.system(size: 22))
                        Text("Unlock with \(authService.biometricType.displayName)")
                            .font(.pgButton)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PGSpacing.md)
                    .background(Color.pgPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                    .pgElevatedShadow()
                }
                .padding(.horizontal, PGSpacing.xl)
                .padding(.bottom, PGSpacing.xxl)
            }
        }
        .task {
            _ = await authService.authenticate()
        }
    }
}

#Preview {
    LockScreenView()
        .environment(BiometricAuthService.shared)
}
