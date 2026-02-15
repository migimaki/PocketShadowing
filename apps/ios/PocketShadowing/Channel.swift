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
    var subtitle: String
    var channelDescription: String
    var coverImageURL: String?
    var iconName: String
    var genre: String

    @Transient var isFollowed: Bool = false

    @Relationship(deleteRule: .cascade)
    var lessons: [Lesson]

    init(id: UUID = UUID(), title: String, subtitle: String = "", description: String, coverImageURL: String? = nil, iconName: String = "globe", genre: String = "Beginner") {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.channelDescription = description
        self.coverImageURL = coverImageURL
        self.iconName = iconName
        self.genre = genre
        self.lessons = []
    }
}
