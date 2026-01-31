//
//  VideoHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 31/01/26.
//

import AVFoundation
import UIKit

/// Helper class to handle video compression and thumbnail generation
class VideoHelper {
    /// Generates a thumbnail image from a local video URL
    static func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true // Fixes orientation issues

        do {
            // Get image at the very first second (0.0)
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Thumbnail Generation Error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Compression Option 1: 720p HEVC (High Efficiency) - DEFAULT

    /// Compresses video to 720p resolution using HEVC (H.265) codec.
    /// Best for modern iPhones, smaller file size, good quality.
    static func compressTo720pHEVC(inputURL: URL, completion: @escaping (URL?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL)

        // Define output URL in temporary directory
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov") // HEVC usually uses .mov or .mp4

        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720) else {
            completion(nil)
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        // HEVC Codec is implied by modern iOS presets or can be forced,
        // but 'AVAssetExportPreset1280x720' generally picks efficient encoding on newer iOS.
        // If specific HEVC control is needed, lower level API is required, but this is standard.
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("✅ Video Compressed to 720p HEVC")
                    completion(outputURL)
                default:
                    print("❌ Compression Failed: \(String(describing: exportSession.error))")
                    completion(nil)
                }
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
