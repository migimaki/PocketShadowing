//
//  LessonListView.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import SwiftUI
import SwiftData

struct LessonListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    let channel: Channel

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isFollowed = false
    @State private var hasLoadedAll = false
    @AppStorage("nativeLanguage") private var nativeLanguage: String = "en"

    // Query lessons for this specific channel
    private var lessons: [Lesson] {
        channel.lessons.sorted { a, b in
            if a.isFree != b.isFree {
                return a.isFree // free lessons first
            }
            return a.date > b.date
        }
    }

    var body: some View {
        ZStack {
            // Background layer
            GradientBackground()

            // Content layer
            VStack {
                if lessons.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    lessonListView
                }
            }

            if isLoading {
                ProgressView(L10n.loadingLessons)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if authManager.isMember {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        toggleFollow()
                    } label: {
                        Text(isFollowed ? L10n.following : L10n.follow)
                            .fontWeight(isFollowed ? .regular : .semibold)
                    }
                }
            }
        }
        .alert(L10n.error, isPresented: $showError) {
            Button(L10n.ok, role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .onAppear {
            // Only fetch from Supabase if no lessons cached yet
            // (ChannelListView already fetches lessons + translations on refresh)
            if lessons.isEmpty {
                fetchLessonsFromSupabase()
            }
            loadFollowState()
        }
        .onChange(of: nativeLanguage) { _, _ in
            loadTranslatedTitles()
            loadChannelTranslation()
        }
    }

    private var lessonListView: some View {
        List {
            // Channel header section
            Section {
                ChannelHeaderView(channel: channel)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            // Lessons section
            Section {
                ForEach(lessons) { lesson in
                    if authManager.isAccessible(lesson) {
                        NavigationLink {
                            PlayerView(lesson: lesson)
                        } label: {
                            LessonRowView(lesson: lesson)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    } else {
                        LessonRowView(lesson: lesson, isLocked: true)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                }
                .onDelete(perform: deleteLessons)

                // Load More button when only initial lessons are cached
                if !hasLoadedAll {
                    Button {
                        loadAllLessons()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text(L10n.loading)
                            } else {
                                Text(L10n.loadMore)
                            }
                            Spacer()
                        }
                        .foregroundStyle(.blue)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .disabled(isLoading)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await fetchLessonsAsync()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(L10n.noLessons, systemImage: "book.closed")
        } description: {
            Text(L10n.pullToRefresh(channelName: channel.displayTitle))
        } actions: {
            Button(L10n.refresh) {
                fetchLessonsFromSupabase()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Follow Actions

    private func loadFollowState() {
        Task {
            let repository = LessonRepository()
            let follows = try? await repository.fetchFollowedChannels()
            let followedIds = Set(follows?.map { $0.channel_id } ?? [])
            isFollowed = followedIds.contains(channel.id)
            channel.isFollowed = isFollowed
        }
    }

    private func toggleFollow() {
        Task {
            let repository = LessonRepository()
            do {
                if isFollowed {
                    try await repository.unfollowChannel(channelId: channel.id)
                    isFollowed = false
                } else {
                    try await repository.followChannel(channelId: channel.id)
                    isFollowed = true
                }
                channel.isFollowed = isFollowed
            } catch {
                print("Failed to toggle follow: \(error)")
            }
        }
    }

    // MARK: - Lesson Actions

    private func fetchLessonsFromSupabase() {
        Task {
            await fetchLessonsAsync()
        }
    }

    private func loadAllLessons() {
        Task {
            await fetchLessonsAsync()
        }
    }

    private func fetchLessonsAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            let repository = LessonRepository()

            // Fetch all lessons for this channel
            let lessonDTOs = try await repository.fetchLessons(for: channel.id)

            // Batch fetch sentences for all lessons (single query)
            let lessonIds = lessonDTOs.map { $0.id }
            let allSentences = try await repository.fetchSentences(forLessonIds: lessonIds)

            // Group sentences by lesson_id client-side
            var sentencesDict: [UUID: [SentenceDTO]] = [:]
            for sentence in allSentences {
                sentencesDict[sentence.lesson_id, default: []].append(sentence)
            }

            // Fetch lesson title translations if native language is not English
            var translations: [UUID: String] = [:]
            if nativeLanguage != "en" {
                translations = try await repository.fetchLessonTranslations(
                    lessonIds: lessonIds,
                    targetLanguage: nativeLanguage
                )
            }

            // Save to SwiftData
            try repository.saveLessonsToSwiftData(
                lessonDTOs,
                sentences: sentencesDict,
                modelContext: modelContext,
                channel: channel,
                translations: translations
            )

            hasLoadedAll = true

        } catch {
            errorMessage = "Failed to fetch lessons: \(error.localizedDescription)"
            showError = true
            print("Failed to fetch lessons: \(error)")
        }

        isLoading = false
    }

    private func loadTranslatedTitles() {
        print("[LessonListView] loadTranslatedTitles: nativeLanguage = '\(nativeLanguage)', lessons count = \(lessons.count)")
        guard nativeLanguage != "en" else {
            // Clear translations when language is English
            for lesson in lessons where lesson.translatedTitle != nil {
                lesson.translatedTitle = nil
            }
            try? modelContext.save()
            return
        }

        let lessonIds = lessons.map { $0.id }
        Task { @MainActor in
            do {
                let repository = LessonRepository()
                let translations = try await repository.fetchLessonTranslations(
                    lessonIds: lessonIds,
                    targetLanguage: nativeLanguage
                )
                print("[LessonListView] loadTranslatedTitles: got \(translations.count) translations for \(lessonIds.count) lessons")
                for lesson in lessons {
                    lesson.translatedTitle = translations[lesson.id]
                }
                try modelContext.save()
                print("[LessonListView] loadTranslatedTitles: saved to SwiftData")
            } catch {
                print("[LessonListView] Failed to load lesson translations: \(error)")
            }
        }
    }

    private func loadChannelTranslation() {
        guard nativeLanguage != "en" else {
            channel.translatedTitle = nil
            channel.translatedDescription = nil
            try? modelContext.save()
            return
        }

        Task { @MainActor in
            do {
                let repository = LessonRepository()
                let translations = try await repository.fetchChannelTranslations(
                    channelIds: [channel.id],
                    targetLanguage: nativeLanguage
                )
                if let translation = translations[channel.id] {
                    channel.translatedTitle = translation.title
                    channel.translatedDescription = translation.description
                }
                try modelContext.save()
            } catch {
                print("[LessonListView] Failed to load channel translation: \(error)")
            }
        }
    }

    private func deleteLessons(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(lessons[index])
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Channel Header View

struct ChannelHeaderView: View {
    let channel: Channel

    var body: some View {
        VStack(spacing: 16) {
            // Channel thumbnail
            if let coverImageURL = channel.coverImageURL,
               let url = URL(string: coverImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 100, height: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        iconFallback
                    @unknown default:
                        iconFallback
                    }
                }
            } else {
                iconFallback
            }

            // Channel title
            Text(channel.displayTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Channel description
            Text(channel.displayDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
        .padding(.bottom, 32)
    }

    private var iconFallback: some View {
        Image(systemName: channel.iconName)
            .font(.system(size: 50))
            .foregroundStyle(.blue)
            .frame(width: 100, height: 100)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Lesson Row View

struct LessonRowView: View {
    let lesson: Lesson
    var isLocked: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Title + Free badge
                HStack(spacing: 6) {
                    Text(lesson.displayTitle)
                        .font(.headline)
                        .lineLimit(2)

                    if lesson.isFree {
                        Text(L10n.free)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }

                // Date only
                HStack {
                    Image(systemName: "calendar")
                    Text(lesson.formattedDate)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
        }
        .opacity(isLocked ? 0.5 : 1.0)
    }
}

#Preview {
    @Previewable @State var channel = Channel(title: "Preview Channel", description: "Preview")

    NavigationStack {
        LessonListView(channel: channel)
    }
    .modelContainer(for: [Channel.self, Lesson.self], inMemory: true)
}
