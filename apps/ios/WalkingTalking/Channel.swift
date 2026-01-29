//
//  Channel.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation
import SwiftData

@Model
final class Channel {
    var id: UUID
    var title: String // Display title for the channel
    var subtitle: String // Short subtitle/tagline
    var channelDescription: String
    var coverImageURL: String? // Cover image URL from series
    var iconName: String
    var language: String // Language code: en, ja, fr

    @Relationship(deleteRule: .cascade)
    var lessons: [Lesson]

    init(id: UUID = UUID(), title: String, subtitle: String = "", description: String, coverImageURL: String? = nil, iconName: String = "globe", language: String = "en") {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.channelDescription = description
        self.coverImageURL = coverImageURL
        self.iconName = iconName
        self.language = language
        self.lessons = []
    }

    // Static channels for each language
    static var euroNewsEnglish: Channel {
        Channel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "English News",
            subtitle: "Daily English language news and practice",
            description: "Daily English lessons based on special days and events",
            iconName: "globe.europe.africa.fill",
            language: "en"
        )
    }

    static var euroNewsJapanese: Channel {
        Channel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "日本語ニュース",
            subtitle: "毎日の日本語ニュースと練習",
            description: "Japanese lessons based on special days and events (ユーロニュース)",
            iconName: "globe.europe.africa.fill",
            language: "ja"
        )
    }

    static var euroNewsFrench: Channel {
        Channel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "Actualités en Français",
            subtitle: "Actualités et pratique quotidiennes en français",
            description: "French lessons based on special days and events (Actualités Euro)",
            iconName: "globe.europe.africa.fill",
            language: "fr"
        )
    }

    // Backwards compatibility
    static var euroNews: Channel {
        euroNewsEnglish
    }
}
