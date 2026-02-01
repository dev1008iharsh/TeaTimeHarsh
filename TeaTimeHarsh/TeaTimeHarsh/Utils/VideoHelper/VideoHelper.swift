//
//  VideoHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//
/*
 📋 AVAssetExportPreset Options (iOS)

 🎞️ Quality-Based Presets
 AVAssetExportPresetLowQuality         // videolowest bitrate/quality
 AVAssetExportPresetMediumQuality      // medium quality export
 AVAssetExportPresetHighestQuality     // maximum quality video export

 📏 Resolution/Size-Based Presets
 AVAssetExportPreset640x480            // 640×480 resolution
 AVAssetExportPreset960x540            // 960×540 resolution
 AVAssetExportPreset1280x720           // 1280×720 resolution
 AVAssetExportPreset1920x1080          // 1920×1080 resolution
 AVAssetExportPreset3840x2160          // 4K UHD resolution

 📦 HEVC-Specific Presets
 AVAssetExportPresetHEVCHighestQuality // HEVC high-quality export
 AVAssetExportPresetHEVC1920x1080      // HEVC 1080p
 AVAssetExportPresetHEVC3840x2160      // HEVC 4K

 🔊 Audio-Only / Other
 AVAssetExportPresetAppleM4A           // audio only (M4A)
 AVAssetExportPresetPassthrough        // passthrough (no re-encode)
 */

import AVFoundation
import UIKit

/// Helper class to handle video compression and thumbnail generation
class VideoHelper {
    /// Generates a thumbnail image from a local video URL
    static func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true // Fixes orientation issues

        // Set maximum size to avoid loading full 4K frame into memory (Performance Optimization)
        imageGenerator.maximumSize = CGSize(width: 600, height: 600)

        do {
            // Get image at the very first second (0.0)
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Thumbnail Generation Error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Compression 720p - DEFAULT

    /// Compresses video to 720p resolution (H.264 if failed then medium).
    static func compressTo720p(inputURL: URL, completion: @escaping (URL?, Float) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL)

        // 1. Prepare Output Path
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // Cleanup old file
        try? FileManager.default.removeItem(at: outputURL)

        // 2. Try Initialize with 720p First 🎯
        var exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720)

        // 3. Fallback Check: If 720p failed (nil), use Medium Quality
        if exportSession == nil {
            print("⚠️ 720p(H.264) preset not supported. Falling back to Medium Quality.")
            exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality)
        }

        // Final Safety Check
        guard let session = exportSession else {
            print("❌ Error: Could not create export session with any preset.")
            completion(nil, 0)
            return
        }

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true

        // 4. Start Export
        let startTime = Date()

        session.exportAsynchronously {
            switch session.status {
            case .completed:
                let processingTime = Date().timeIntervalSince(startTime)
                print("✅ Compression Success! Time: \(String(format: "%.2f", processingTime))s")

                // 5. iOS 17 Modern Way to get Duration 🚀
                Task {
                    do {
                        let duration = try await urlAsset.load(.duration)
                        let seconds = Float(duration.seconds)

                        DispatchQueue.main.async {
                            completion(outputURL, seconds)
                        }
                    } catch {
                        print("⚠️ Failed to load duration: \(error)")
                        DispatchQueue.main.async {
                            completion(outputURL, 0)
                        }
                    }
                }

            case .failed, .cancelled:
                print("❌ Compression Failed: \(String(describing: session.error))")
                DispatchQueue.main.async { completion(nil, 0) }

            default:
                DispatchQueue.main.async { completion(nil, 0) }
            }
        }
    }
    /*
     // MARK: - Compression Option 2: 480p MP4 (Standard)

     /// Compresses video to 480p resolution using H.264 (Standard MP4).
     /// Use this if you want maximum compatibility with very old devices.
     static func compressTo480pMP4(inputURL: URL, completion: @escaping (URL?) -> Void) {
         let urlAsset = AVURLAsset(url: inputURL)

         let outputURL = FileManager.default.temporaryDirectory
             .appendingPathComponent(UUID().uuidString)
             .appendingPathExtension("mp4")

         // Preset 640x480 for standard definition
         guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset640x480) else {
             completion(nil)
             return
         }

         exportSession.outputURL = outputURL
         exportSession.outputFileType = .mp4 // Standard MP4
         exportSession.shouldOptimizeForNetworkUse = true

         exportSession.exportAsynchronously {
             DispatchQueue.main.async {
                 switch exportSession.status {
                 case .completed:
                     print("✅ Video Compressed to 480p MP4")
                     completion(outputURL)
                 default:
                     print("❌ Compression Failed")
                     completion(nil)
                 }
             }
         }
     }*/
}
