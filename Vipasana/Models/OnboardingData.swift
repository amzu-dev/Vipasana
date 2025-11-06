//
//  OnboardingData.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import Foundation
import SwiftData

@Model
final class OnboardingData {
    var hasCompletedOnboarding: Bool
    var userName: String
    var meditationExperience: String
    var dailyGoalMinutes: Int
    var preferredTime: String
    var completedAt: Date?

    init(
        hasCompletedOnboarding: Bool = false,
        userName: String = "",
        meditationExperience: String = "",
        dailyGoalMinutes: Int = 15,
        preferredTime: String = "",
        completedAt: Date? = nil
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.userName = userName
        self.meditationExperience = meditationExperience
        self.dailyGoalMinutes = dailyGoalMinutes
        self.preferredTime = preferredTime
        self.completedAt = completedAt
    }
}
