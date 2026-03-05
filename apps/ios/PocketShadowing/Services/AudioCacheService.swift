//
//  AudioCacheService.swift
//  WalkingTalking
//
//  Created by Claude Code on 2025/11/01.
//

import Foundation
import AVFoundation

/// Service for downloading and caching audio files from Supabase Storage
class AudioCacheService {
    static let shared = AudioCacheService()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Create cache directory in Documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("AudioCache", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get local file path for a given audio URL
    func localFilePath(for audioURL: String) -> URL {
        let fileName = audioURL.components(separatedBy: "/").last ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent(fileName)
    }

    /// Check if audio file is cached locally
    func isCached(audioURL: String) -> Bool {
        let localPath = localFilePath(for: audioURL)
        return fileManager.fileExists(atPath: localPath.path)
    }

    /// Download audio file if not cached, return local file URL
    func getAudioFile(from audioURL: String) async throws -> URL {
        let localPath = localFilePath(for: audioURL)

        // Return cached file if exists
        if fileManager.fileExists(atPath: localPath.path) {
            print("✅ Using cached audio: \(localPath.lastPathComponent)")
            return localPath
        }

        // Download file
        print("⬇️  Downloading audio from: \(audioURL)")
        guard let url = URL(string: audioURL) else {
            throw AudioCacheError.invalidURL(audioURL)
        }

        let (tempURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AudioCacheError.downloadFailed(audioURL)
        }

        // Move to cache directory
        try fileManager.moveItem(at: tempURL, to: localPath)
        print("✅ Audio downloaded and cached: \(localPath.lastPathComponent)")

        return localPath
    }

    /// Download multiple audio files concurrently
    func downloadAudioFiles(urls: [String]) async throws -> [URL] {
        try await withThrowingTaskGroup(of: URL.self) { group in
            for url in urls {
                group.addTask {
                    try await self.getAudioFile(from: url)
                }
            }

            var localURLs: [URL] = []
            for try await url in group {
                localURLs.append(url)
            }
            return localURLs
        }
    }

    /// Clear all cached audio files
    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }
        print("🗑️ Audio cache cleared")
    }

    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            guard let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                return total
            }
            return total + Int64(fileSize)
        }
    }

    /// Get formatted cache size string
    func getFormattedCacheSize() -> String {
        let bytes = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Errors

enum AudioCacheError: Error, LocalizedError {
    case invalidURL(String)
    case downloadFailed(String)
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .downloadFailed(let url):
            return "Failed to download audio from: \(url)"
        case .fileNotFound(let url):
            return "Audio file not found: \(url)"
        }
    }
}
