//
//  PDFHelper.swift
//  TeaTimeHarsh
//
//  Created by Harsh on 01/02/26.
//

import PDFKit
import UIKit

final class PDFHelper {
    // MARK: - 1. Single Page (Centered) 📄

    static func generateSinglePageThumbnail(of size: CGSize, for documentUrl: URL) -> UIImage? {
        // Load Document & Page 1
        guard let document = CGPDFDocument(documentUrl as CFURL),
              let page = document.page(at: 1) else { return nil }

        // Calculate Scale & Center Position
        let pageRect = page.getBoxRect(.mediaBox)
        let scale = min(size.width / pageRect.width, size.height / pageRect.height)

        let drawnW = pageRect.width * scale
        let drawnH = pageRect.height * scale
        let startX = (size.width - drawnW) / 2
        let startY = (size.height - drawnH) / 2

        // Draw Image
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size)) // White Background

            // Flip Coordinates for PDF
            ctx.cgContext.translateBy(x: 0.0, y: size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            // Center & Draw
            ctx.cgContext.translateBy(x: startX, y: startY)
            ctx.cgContext.scaleBy(x: scale, y: scale)
            ctx.cgContext.drawPDFPage(page)
        }
    }

    // MARK: - 2. Two Pages (Side-by-Side) 📖

    static func generateTwoPageThumbnail(of size: CGSize, for documentUrl: URL) -> UIImage? {
        // Load Page 1 (Mandatory) & Page 2 (Optional)
        guard let document = CGPDFDocument(documentUrl as CFURL),
              let page1 = document.page(at: 1) else { return nil }
        let page2 = document.page(at: 2)

        // Calculate Combined Dimensions
        let rect1 = page1.getBoxRect(.mediaBox)
        let rect2 = page2?.getBoxRect(.mediaBox) ?? .zero

        let totalW = rect1.width + rect2.width
        let maxH = max(rect1.height, rect2.height)

        // Calculate Scale to Fit Both
        let scale = min(size.width / totalW, size.height / maxH)

        // Calculate Center Position
        let startX = (size.width - (totalW * scale)) / 2
        let startY = (size.height - (maxH * scale)) / 2

        // Draw Image
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.tertiarySystemGroupedBackground.set()
            ctx.fill(CGRect(origin: .zero, size: size)) // White Background

            // Flip Coordinates
            ctx.cgContext.translateBy(x: 0.0, y: size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            // Draw Page 1 (Left/Center)
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: startX, y: startY)
            ctx.cgContext.scaleBy(x: scale, y: scale)
            ctx.cgContext.drawPDFPage(page1)
            ctx.cgContext.restoreGState()

            // Draw Page 2 (Right - if exists)
            if let page2 = page2 {
                ctx.cgContext.saveGState()
                let page2X = startX + (rect1.width * scale) // Move to right of Page 1
                ctx.cgContext.translateBy(x: page2X, y: startY)
                ctx.cgContext.scaleBy(x: scale, y: scale)
                ctx.cgContext.drawPDFPage(page2)
                ctx.cgContext.restoreGState()
            }
        }
    }

    /// Compresses a PDF by converting pages to images and re-saving them with lower quality.
    /// - Parameters:
    ///   - sourceURL: Original PDF URL
    ///   - quality: 0.0 to 1.0 (Recommended: 0.5 for 50% quality)
    /// - Returns: Compressed PDF URL
    static func compressPDF(sourceURL: URL, quality: CGFloat = 0.5) -> URL? {
        guard let document = PDFDocument(url: sourceURL) else { return nil }

        // Create a new PDF document
        let compressedDocument = PDFDocument()

        for i in 0 ..< document.pageCount {
            guard let page = document.page(at: i) else { continue }

            // 1. Convert Page to Image
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)

            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            // 2. Compress Image (JPEG Compression)
            guard let compressedData = image.jpegData(compressionQuality: quality),
                  let compressedImage = UIImage(data: compressedData),
                  let newPage = PDFPage(image: compressedImage) else { continue }

            // 3. Add to new Document
            compressedDocument.insert(newPage, at: i)
        }

        // 4. Save to Temp
        let fileName = "compressed_\(UUID().uuidString).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if compressedDocument.write(to: tempURL) {
            return tempURL
        } else {
            return nil
        }
    }
}
