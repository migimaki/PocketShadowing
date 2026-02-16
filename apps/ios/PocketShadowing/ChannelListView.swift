//
//  ChannelListView.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import SwiftUI
import SwiftData

struct ChannelListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showSettings = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var followedChannelIds: Set<UUID> = []
    @State private var followOrder: [UUID] = [] // newest follow first
    @AppStorage("nativeLanguage") private var nativeLanguage: String = "en"

    private let repository = LessonRepository()

    // Computed property to get all channels (all English)
    private var channels: [Channel] {
        let descriptor = FetchDescriptor<Channel>(
            sortBy: [SortDescriptor(\Channel.title)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var myChannels: [Channel] {
        let followed = channels.filter { followedChannelIds.contains($0.id) }
        return followed.sorted { a, b in
            let indexA = followOrder.firstIndex(of: a.id) ?? Int.max
            let indexB = followOrder.firstIndex(of: b.id) ?? Int.max
            return indexA < indexB
        }
    }

    private var beginnerChannels: [Channel] {
        channels.filter { $0.genre == "Beginner" }
    }

    private var intermediateChannels: [Channel] {
        channels.filter { $0.genre == "Intermediate" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer
                GradientBackground()

                // Content layer
                VStack {
                    if isLoading {
                        ProgressView("Loading channels...")
                    } else if channels.isEmpty {
                        // Empty state
                        ContentUnavailableView {
                            Label("No Channels", systemImage: "antenna.radiowaves.left.and.right.slash")
                        } description: {
                            Text("No English channels available.")
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                ChannelSection(title: "My Channels", channels: myChannels, cardSize: 220, isMyChannels: true, emptyText: "No channels followed yet.")
                                ChannelSection(title: "Beginner", channels: beginnerChannels, cardSize: 160)
                                ChannelSection(title: "Intermediate", channels: intermediateChannels, cardSize: 160, emptyText: "Coming soon.")
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await fetchChannelsFromSupabase()
                            await loadFollowStates()
                        }
                    }
                }
            }
            .navigationTitle("Channels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .onAppear {
                // Fetch channels from Supabase if needed
                if channels.isEmpty {
                    Task {
                        await fetchChannelsFromSupabase()
                        await loadFollowStates()
                        await loadLessonTranslations()
                    }
                } else {
                    Task {
                        await loadFollowStates()
                        await loadLessonTranslations()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: nativeLanguage) { _, _ in
                Task {
                    await loadLessonTranslations()
                }
            }
        }
    }

    private func loadFollowStates() async {
        do {
            let follows = try await repository.fetchFollowedChannels()
            followedChannelIds = Set(follows.map { $0.channel_id })
            followOrder = follows.map { $0.channel_id }
        } catch {
            print("Failed to load follow states: \(error)")
        }
    }

    private func loadLessonTranslations() async {
        print("[ChannelListView] loadLessonTranslations: nativeLanguage = '\(nativeLanguage)'")
        guard nativeLanguage != "en" else {
            // Clear translations when language is English
            let allLessons = channels.flatMap { $0.lessons }
            for lesson in allLessons where lesson.translatedTitle != nil {
                lesson.translatedTitle = nil
            }
            try? modelContext.save()
            return
        }

        let allLessons = channels.flatMap { $0.lessons }
        let lessonIds = allLessons.map { $0.id }
        guard !lessonIds.isEmpty else {
            print("[ChannelListView] loadLessonTranslations: no lessons to translate")
            return
        }

        do {
            let translations = try await repository.fetchLessonTranslations(
                lessonIds: lessonIds,
                targetLanguage: nativeLanguage
            )
            print("[ChannelListView] loadLessonTranslations: got \(translations.count) translations for \(lessonIds.count) lessons")
            for lesson in allLessons {
                lesson.translatedTitle = translations[lesson.id]
            }
            try modelContext.save()
            print("[ChannelListView] loadLessonTranslations: saved to SwiftData")
        } catch {
            print("[ChannelListView] Failed to load lesson translations: \(error)")
        }
    }

    private func fetchChannelsFromSupabase() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all channels from Supabase
            let channelDTOs = try await repository.fetchAllChannels()

            // Save to SwiftData
            try repository.saveChannelsToSwiftData(channelDTOs, modelContext: modelContext)

            print("Successfully fetched and saved \(channelDTOs.count) English channels from Supabase")
        } catch {
            errorMessage = "Failed to fetch channels: \(error.localizedDescription)"
            print("Error fetching channels: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Channel Section

struct ChannelSection: View {
    let title: String
    let channels: [Channel]
    var cardSize: CGFloat = 220
    var isMyChannels: Bool = false
    var emptyText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            if channels.isEmpty {
                if let emptyText {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(channels) { channel in
                            if isMyChannels {
                                MyChannelCard(channel: channel, cardSize: cardSize)
                            } else {
                                NavigationLink {
                                    LessonListView(channel: channel)
                                } label: {
                                    ChannelCard(channel: channel, cardSize: cardSize)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

// MARK: - My Channel Card

struct MyChannelCard: View {
    let channel: Channel
    var cardSize: CGFloat = 220

    private var latestLesson: Lesson? {
        channel.lessons.sorted { $0.date > $1.date }.first
    }

    var body: some View {
        NavigationLink {
            LessonListView(channel: channel)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Square thumbnail image
                channelThumbnail

                // Bottom content area with fixed height for uniform cards
                VStack(alignment: .leading, spacing: 0) {
                    // Latest lesson info
                    VStack(alignment: .leading, spacing: 4) {
                        if let lesson = latestLesson {
                            Text(channel.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(lesson.displayTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                        } else {
                            Text(channel.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    Spacer(minLength: 4)

                    // Play button row
                    if let lesson = latestLesson {
                        HStack {
                            NavigationLink {
                                PlayerView(lesson: lesson)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    } else {
                        Spacer().frame(height: 12)
                    }
                }
                .frame(height: 120)
            }
            .frame(width: cardSize)
            .background(Color(.systemGray6).opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var channelThumbnail: some View {
        if let coverImageURL = channel.coverImageURL, let url = URL(string: coverImageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: cardSize, height: cardSize)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardSize, height: cardSize)
                        .clipped()
                case .failure:
                    channelIconPlaceholder
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            channelIconPlaceholder
        }
    }

    private var channelIconPlaceholder: some View {
        Image(systemName: channel.iconName)
            .font(.largeTitle)
            .foregroundStyle(.blue)
            .frame(width: cardSize, height: cardSize)
            .background(Color.blue.opacity(0.1))
    }
}

// MARK: - Channel Card

struct ChannelCard: View {
    let channel: Channel
    var cardSize: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Square thumbnail image
            if let coverImageURL = channel.coverImageURL, let url = URL(string: coverImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: cardSize, height: cardSize)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardSize, height: cardSize)
                            .clipped()
                    case .failure:
                        channelIconPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                channelIconPlaceholder
            }

            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(channel.channelDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
        }
        .frame(width: cardSize)
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var channelIconPlaceholder: some View {
        Image(systemName: channel.iconName)
            .font(.largeTitle)
            .foregroundStyle(.blue)
            .frame(width: cardSize, height: cardSize)
            .background(Color.blue.opacity(0.1))
    }
}

#Preview {
    ChannelListView()
        .modelContainer(for: [Channel.self, Lesson.self, Sentence.self], inMemory: true)
}
