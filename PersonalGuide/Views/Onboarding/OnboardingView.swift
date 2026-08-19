// MARK: - OnboardingView.swift
// PersonalGuide
//
// First-run onboarding experience — shown once after fresh install.
// Three swipeable slides explaining the app's core value propositions,
// followed by notification permission request.
// Dismissed permanently via UserDefaults ("PG_ONBOARDING_COMPLETE").

import SwiftUI
import UserNotifications

struct OnboardingView: View {

    @Binding var isOnboardingComplete: Bool

    @State private var currentPage: Int = 0
    @State private var showNotificationPrompt = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "list.bullet.clipboard.fill",
            color: Color(hex: "0A84FF"),
            title: "Your life admin,\norganised.",
            body: "Personal Guide tracks every open task — insurance renewals, returns, bills, document renewals — in one focused workspace."
        ),
        OnboardingPage(
            icon: "doc.viewfinder.fill",
            color: Color(hex: "30D158"),
            title: "Scan. Extract.\nAct.",
            body: "Point your camera at any document. Personal Guide reads it using on-device OCR and builds an action plan instantly — no cloud required."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            color: Color(hex: "5E5CE6"),
            title: "Private by\ndesign.",
            body: "Your data never leaves your iPhone. Zero tracking, zero accounts. Enable Face ID to add an extra security layer."
        )
    ]

    var body: some View {
        ZStack {
            Color.pgBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Slide Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.pgSpring, value: currentPage)

                // MARK: - Progress Dots
                HStack(spacing: PGSpacing.sm) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.pgPrimary : Color.pgBorder)
                            .frame(width: index == currentPage ? 20 : 6, height: 6)
                            .animation(.pgSpring, value: currentPage)
                    }
                }
                .padding(.top, PGSpacing.lg)

                // MARK: - Primary CTA
                VStack(spacing: PGSpacing.sm) {
                    if currentPage < pages.count - 1 {
                        // Next page
                        Button {
                            withAnimation(.pgSpring) {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.pgButton)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PGSpacing.md)
                                .background(Color.pgPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                                .pgElevatedShadow()
                        }

                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.pgBody)
                        .foregroundStyle(.pgTextSecondary)
                    } else {
                        // Last page — request notifications then complete
                        Button {
                            requestNotificationsAndComplete()
                        } label: {
                            Text("Get Started")
                                .font(.pgButton)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PGSpacing.md)
                                .background(Color.pgPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: PGRadius.medium))
                                .pgElevatedShadow()
                        }
                    }
                }
                .padding(.horizontal, PGSpacing.xl)
                .padding(.top, PGSpacing.lg)
                .padding(.bottom, PGSpacing.xxl)
            }
        }
    }

    // MARK: - Actions

    private func requestNotificationsAndComplete() {
        Task {
            // Request permission for deadline reminders
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                completeOnboarding()
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "PG_ONBOARDING_COMPLETE")
        withAnimation(.pgSpring) {
            isOnboardingComplete = true
        }
    }
}

// MARK: - OnboardingPage Model

struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let body: String
}

// MARK: - OnboardingPageView

struct OnboardingPageView: View {

    let page: OnboardingPage

    var body: some View {
        VStack(spacing: PGSpacing.lg) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(page.color)
            }
            .pgElevatedShadow()

            // Text
            VStack(spacing: PGSpacing.sm) {
                Text(page.title)
                    .font(.pgHeading)
                    .foregroundStyle(.pgTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.pgBody)
                    .foregroundStyle(.pgTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PGSpacing.lg)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
