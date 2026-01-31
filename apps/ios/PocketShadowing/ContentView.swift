//
//  ContentView.swift
//  WalkingTalking
//
//  Created by KEISUKE YANAGISAWA on 2025/10/30.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdDate, order: .reverse) private var allLessons: [Lesson]

    @State private var showSettings = false

    // Filter lessons for English only
    private var lessons: [Lesson] {
        let language = UserSettings.learningLanguage
        return allLessons.filter { $0.language == language }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer
                GradientBackground()

                // Content layer
                VStack {
                    if lessons.isEmpty {
                        emptyStateView
                    } else {
                        lessonListView
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            loadSampleDataIfNeeded()
        }
    }

    private var lessonListView: some View {
        List {
            ForEach(lessons) { lesson in
                NavigationLink {
                    PlayerView(lesson: lesson)
                } label: {
                    LessonRowView(lesson: lesson)
                }
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteLessons)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Lessons")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Lessons Yet")
                .font(.title2)
                .fontWeight(.semibold)

            if allLessons.isEmpty {
                Text("Sample lesson will be loaded automatically")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No English lessons available. Try checking the Channels tab to download content.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Lessons")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
    }

    private func loadSampleDataIfNeeded() {
        if lessons.isEmpty {
            LessonDataService.initializeSampleData(context: modelContext)
        }
    }

    private func deleteLessons(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let lessonToDelete = lessons[index]
                modelContext.delete(lessonToDelete)
            }
        }
    }
}

// LessonRowView moved to LessonListView.swift

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Lesson.self, configurations: config)

    // Create sample lesson
    let lesson = Lesson(
        title: "6 Minute English",
        description: "AI and Art - Today, we're diving into a fascinating question"
    )

    for i in 0..<12 {
        let sentence = Sentence(
            text: "Sample sentence \(i + 1)",
            order: i
        )
        lesson.sentences.append(sentence)
    }

    container.mainContext.insert(lesson)

    return ContentView()
        .modelContainer(container)
}
