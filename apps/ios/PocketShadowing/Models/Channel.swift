//
//  Channel.swift
//  PocketShadowing
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation
import SwiftData

@Model
final class Channel {
    var id: UUID
    var title: String
    var channelDescription: String
    var coverImageURL: String?
    var iconName: String
    var genre: String
    var translatedTitle: String?
    var translatedDescription: String?

    @Transient var isFollowed: Bool = false

    @Relationship(deleteRule: .cascade)
    var lessons: [Lesson]

    var displayTitle: String {
        translatedTitle ?? title
    }

    var displayDescription: String {
        translatedDescription ?? channelDescription
    }

    init(id: UUID = UUID(), title: String, description: String, coverImageURL: String? = nil, iconName: String = "globe", genre: String = "Beginner") {
        self.id = id
        self.title = title
        self.channelDescription = description
        self.coverImageURL = coverImageURL
        self.iconName = iconName
        self.genre = genre
        self.lessons = []
    }
}
