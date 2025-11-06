//
//  MeditationSession.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import Foundation
import SwiftData

@Model
final class MeditationSession {
    var startTime: Date
    var duration: TimeInterval // in seconds
    var completed: Bool
    var sessionType: String // "15min", "30min", "45min", "60min"

    init(startTime: Date, duration: TimeInterval, completed: Bool = false, sessionType: String) {
        self.startTime = startTime
        self.duration = duration
        self.completed = completed
        self.sessionType = sessionType
    }

    var endTime: Date {
        startTime.addingTimeInterval(duration)
    }
}
