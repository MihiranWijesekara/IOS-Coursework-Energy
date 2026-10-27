//
//  BillTextRecognitionService.swift
//  ios-final-coursework
//
//  Complete Vision OCR, Intelligent Sri Lankan Bill Parser & Validator Engine
//  Supports CEB e-Bills (SMS/WhatsApp), CEB Printed Invoices, and LECO Statements.
//

import Foundation
import UIKit
import Vision
import CoreImage
import PDFKit
import ImageIO

// MARK: - 1. Recognized Text Line Model
public struct RecognizedTextLine: Equatable, Sendable {
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect

    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

// MARK: - 2. OCR Errors
public enum BillOCRError: LocalizedError, Equatable {
    case invalidImage
    case imageTooSmall
    case unsupportedPDF
    case noTextDetected
    case cancelled
    case recognitionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected file could not be decoded as a valid image."
        case .imageTooSmall:
            return "The image resolution is too low for reliable OCR. Please use a clearer screenshot or photo."
        case .unsupportedPDF:
            return "The selected PDF document is encrypted, empty, or could not be rendered."
        case .noTextDetected:
            return "No readable electricity bill text was detected in the image."
        case .cancelled:
            return "Bill text recognition was cancelled."
        case .recognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        }
    }
}

// MARK: - 3. Real Vision OCR Service
public final class ElectricityBillOCRService: Sendable {
    public init() {}

    /// Renders a PDF document URL into a composite or first-page UIImage for Vision OCR.
    public func renderImage(fromPDF url: URL) throws -> UIImage {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            throw BillOCRError.unsupportedPDF
        }

        let maxPages = min(document.pageCount, 2)
        var pageImages: [UIImage] = []
        let scale: CGFloat = 2.5

        for pageIndex in 0..<maxPages {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let targetSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let img = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: targetSize))
                ctx.cgContext.translateBy(x: 0, y: targetSize.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            pageImages.append(img)
        }

        guard !pageImages.isEmpty else {
            throw BillOCRError.unsupportedPDF
        }

        if pageImages.count == 1 {
            return pageImages[0]
        }

        let totalHeight = pageImages.reduce(0) { $0 + $1.size.height }
        let maxWidth = pageImages.map(\.size.width).max() ?? 1000
        let combinedSize = CGSize(width: maxWidth, height: totalHeight)
        let combinedRenderer = UIGraphicsImageRenderer(size: combinedSize)
        return combinedRenderer.image { _ in
            var currentY: CGFloat = 0
            for img in pageImages {
                img.draw(in: CGRect(x: 0, y: currentY, width: img.size.width, height: img.size.height))
                currentY += img.size.height
            }
        }
    }

    /// Normalizes image orientation to `.up` so rotated camera photos and landscape screenshots are physically oriented correctly.
    public static func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// Applies a gentle non-destructive CIFilter contrast and sharpen pass (CIColorControls contrast 1.12, CISharpenLuminance sharpness 0.35).
    nonisolated public static func preprocessImageForOCR(_ inputImage: UIImage) -> UIImage? {
        guard let ciInput = CIImage(image: inputImage) else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])

        var output = ciInput
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.12, forKey: kCIInputContrastKey)
            if let result = colorFilter.outputImage {
                output = result
            }
        }

        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(output, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.35, forKey: kCIInputSharpnessKey)
            if let result = sharpenFilter.outputImage {
                output = result
            }
        }

        guard let cgImg = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImg, scale: inputImage.scale, orientation: .up)
    }

    /// Executes Vision text recognition request on the specified CGImage.
    nonisolated private static func runVisionRequest(on cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> [RecognizedTextLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US", "en-GB"]

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: orientation,
            options: [:]
        )

        try handler.perform([request])

        let observations = request.results ?? []
        let rawFragments: [RecognizedTextLine] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }
            let trimmed = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return RecognizedTextLine(
                text: trimmed,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            )
        }

        guard !rawFragments.isEmpty else {
            return []
        }

        return groupAndOrderLines(rawFragments)
    }

    /// Performs programmatic OCR using Apple's Vision framework (`VNRecognizeTextRequest`), with orientation normalization and fallback preprocessing.
    public func recognizeText(from image: UIImage) async throws -> [RecognizedTextLine] {
        try Task.checkCancellation()

        // Phase 3: Convert UIImage.imageOrientation to .up so rotated camera photos & landscape screenshots are oriented correctly
        let normalizedImage = Self.normalizeImageOrientation(image)

        guard let cgImage = normalizedImage.cgImage else {
            throw BillOCRError.invalidImage
        }

        if cgImage.width < 120 || cgImage.height < 120 {
            throw BillOCRError.imageTooSmall
        }

        return try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()

            // Pass 1: Original normalized image
            let pass1Lines: [RecognizedTextLine]
            do {
                pass1Lines = try Self.runVisionRequest(on: cgImage, orientation: .up)
            } catch {
                throw BillOCRError.recognitionFailed(error.localizedDescription)
            }

            try Task.checkCancellation()

            let pass1AvgConfidence: Float = pass1Lines.isEmpty ? 0 : (pass1Lines.reduce(0) { $0 + $1.confidence } / Float(pass1Lines.count))
            let pass1HasNumbers = pass1Lines.contains { line in line.text.contains { $0.isNumber } }

            // Phase 3: Secondary CIFilter contrast/sharpen pass only if first pass yields low confidence (<0.70) or missing numeric readings
            let needsSecondaryPass = pass1Lines.isEmpty || pass1AvgConfidence < 0.70 || !pass1HasNumbers

            if needsSecondaryPass,
               let preprocessed = Self.preprocessImageForOCR(normalizedImage),
               let preprocessedCG = preprocessed.cgImage {
                try Task.checkCancellation()
                if let pass2Lines = try? Self.runVisionRequest(on: preprocessedCG, orientation: .up), !pass2Lines.isEmpty {
                    let pass2AvgConfidence = pass2Lines.reduce(0) { $0 + $1.confidence } / Float(pass2Lines.count)
                    let pass2HasNumbers = pass2Lines.contains { line in line.text.contains { $0.isNumber } }

                    if pass1Lines.isEmpty || (!pass1HasNumbers && pass2HasNumbers) || (pass2AvgConfidence > pass1AvgConfidence && pass2HasNumbers) {
                        return pass2Lines
                    }
                }
            }

            guard !pass1Lines.isEmpty else {
                throw BillOCRError.noTextDetected
            }

            return pass1Lines
        }.value
    }

    /// Groups horizontally aligned text fragments on the same visual row and orders rows top-to-bottom.
    /// Grouping lines whose midY are within 0.012 normalized height and sorting left-to-right by minX for multi-column CEB/LECO bills.
    public static func groupAndOrderLines(_ fragments: [RecognizedTextLine]) -> [RecognizedTextLine] {
        // Vision coordinates have origin (0,0) at bottom-left, so higher midY is higher on screen.
        let sortedByY = fragments.sorted { lhs, rhs in
            if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.012 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }
            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }

        var mergedRows: [[RecognizedTextLine]] = []
        for fragment in sortedByY {
            if var lastRow = mergedRows.last,
               let firstInRow = lastRow.first,
               abs(firstInRow.boundingBox.midY - fragment.boundingBox.midY) <= 0.012 {
                lastRow.append(fragment)
                mergedRows[mergedRows.count - 1] = lastRow
            } else {
                mergedRows.append([fragment])
            }
        }

        return mergedRows.map { row in
            let orderedRow = row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
            let combinedText = orderedRow.map(\.text).joined(separator: " ")
            let avgConfidence = orderedRow.map(\.confidence).reduce(0, +) / Float(orderedRow.count)
            let unionBox = orderedRow.dropFirst().reduce(orderedRow[0].boundingBox) { $0.union($1.boundingBox) }
            return RecognizedTextLine(text: combinedText, confidence: avgConfidence, boundingBox: unionBox)
        }
    }

    public static func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - 4. Dynamic Electricity Bill Parser
public final class ElectricityBillParser: @unchecked Sendable {
    private let validator = ElectricityBillValidator()

    public init() {}

    public func parse(lines: [RecognizedTextLine]) -> ExtractedElectricityBill {
        let filteredLines = filterMessagingChrome(from: lines)
        let rawText = lines.map(\.text).joined(separator: "\n")
        let format = detectFormat(from: filteredLines)

        var bill = ExtractedElectricityBill()
        bill.formatType = format
        bill.rawOCRText = rawText

        switch format {
        case .cebEBill:
            bill.provider = "Ceylon Electricity Board (CEB)"
            parseCEBeBill(lines: filteredLines, into: &bill)
        case .cebPrinted:
            bill.provider = "Ceylon Electricity Board (CEB)"
            parsePrintedOrStandardBill(lines: filteredLines, into: &bill)
        case .lecoBill:
            bill.provider = "Lanka Electricity Company (LECO)"
            parsePrintedOrStandardBill(lines: filteredLines, into: &bill)
        case .standard, .unknown:
            parsePrintedOrStandardBill(lines: filteredLines, into: &bill)
        }

        // Compute aggregate confidence from recognized fields or OCR lines
        if !bill.fieldMetadata.isEmpty {
            let total = bill.fieldMetadata.values.map(\.confidence).reduce(0, +)
            bill.extractionConfidence = total / Float(bill.fieldMetadata.count)
        } else if !filteredLines.isEmpty {
            let total = filteredLines.map(\.confidence).reduce(0, +)
            bill.extractionConfidence = (total / Float(filteredLines.count)) * 0.5
        }

        bill.validationWarnings = validator.validate(bill)
        return bill
    }

    public func parse(rawText: String) -> ExtractedElectricityBill {
        let syntheticLines = rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { idx, line in
                RecognizedTextLine(
                    text: line,
                    confidence: 0.95,
                    boundingBox: CGRect(x: 0, y: Double(1000 - idx * 20) / 1000.0, width: 1, height: 0.015)
                )
            }
        return parse(lines: syntheticLines)
    }

    // MARK: - Format Detection
    private func detectFormat(from lines: [RecognizedTextLine]) -> BillFormatType {
        let joined = lines.map(\.text).joined(separator: "\n").lowercased()
        let cebEBillSignals = [
            "ceb e-bill", "ebill.edl.lk", "a/c no", "b/f", "ssc levy", "sscl levy", "monthly bill", "view e-bill"
        ]
        let cebSignalCount = cebEBillSignals.filter { joined.contains($0) }.count
        if cebSignalCount >= 3 {
            return .cebEBill
        }
        if joined.contains("lanka electricity company") || joined.contains("leco") {
            return .lecoBill
        }
        if joined.contains("ceylon electricity board") || joined.contains("ceb") {
            return .cebPrinted
        }
        if joined.contains("kwh") || joined.contains("electricity") || joined.contains("meter") || joined.contains("account") {
            return .standard
        }
        return .unknown
    }

    // Filter out WhatsApp / SMS status bar and forwarding chrome
    private func filterMessagingChrome(from lines: [RecognizedTextLine]) -> [RecognizedTextLine] {
        lines.filter { line in
            let lower = line.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if lower == "forwarded" || lower == "↪ forwarded" { return false }
            if lower == "open this link to view your electricity bill." { return false }
            // Ignore standalone message timestamps like "00:38" or "12:45 PM"
            if lower.range(of: #"^\d{1,2}:\d{2}\s*(?:am|pm)?$"#, options: .regularExpression) != nil {
                return false
            }
            return true
        }
    }

    // MARK: - CEB e-Bill SMS / WhatsApp Parser
    private func parseCEBeBill(lines: [RecognizedTextLine], into bill: inout ExtractedElectricityBill) {
        for (index, item) in lines.enumerated() {
            let line = item.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // 1. A/C No: 5410264908 (D1)
            if line.range(of: #"(?:A\s*/?\s*C\s*No|Account\s*(?:No|Number))"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let rawAcct = firstCapture(in: line, pattern: #"(?:A\s*/?\s*C\s*No|Account\s*(?:No|Number))\s*[:\-]?\s*([0-9OIlSB]{8,14})"#, group: 1) {
                    let (cleanedAcct, wasCleaned) = normalizeNumericToken(rawAcct)
                    bill.accountNumber = cleanedAcct
                    bill.fieldMetadata["accountNumber"] = FieldExtractionMetadata(
                        fieldName: "Account Number",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: wasCleaned
                    )
                }

                if let tariff = firstCapture(in: line, pattern: #"\(([A-Za-z0-9\s\-]{1,8})\)"#, group: 1) {
                    bill.tariffCode = tariff.trimmingCharacters(in: .whitespaces)
                    bill.fieldMetadata["tariffCode"] = FieldExtractionMetadata(
                        fieldName: "Tariff Category",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: false
                    )
                }

                // Customer Name on the immediately following line
                if index + 1 < lines.count {
                    let nextItem = lines[index + 1]
                    let candidateName = nextItem.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if isLikelyCustomerName(candidateName) {
                        bill.customerName = candidateName
                        bill.fieldMetadata["customerName"] = FieldExtractionMetadata(
                            fieldName: "Customer Name",
                            rawLine: candidateName,
                            confidence: nextItem.confidence,
                            wasOCRCleaned: false
                        )
                    }
                }
                continue
            }

            // 2. B/F: Rs. 2,987.07
            if line.range(of: #"^(?:B\s*/\s*F|Brought\s*Forward)\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amount, cleaned) = extractDecimalCurrency(from: line) {
                    bill.broughtForward = amount
                    bill.fieldMetadata["broughtForward"] = FieldExtractionMetadata(
                        fieldName: "Brought Forward",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                continue
            }

            // 3. Payments: Rs. 2,200.00
            if line.range(of: #"^Payments?\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amount, cleaned) = extractDecimalCurrency(from: line) {
                    bill.payments = amount
                    bill.fieldMetadata["payments"] = FieldExtractionMetadata(
                        fieldName: "Payments",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                continue
            }

            // 4. Outstanding: Rs. 787.07 by 2026-09-17
            if line.range(of: #"^Outstanding\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                let amountSegment = line.replacingOccurrences(
                    of: #"\bby\s+[0-9OIlSB]{4}[\-/][0-9OIlSB]{2}[\-/][0-9OIlSB]{2}.*$"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                if let (amount, cleaned) = extractDecimalCurrency(from: amountSegment) {
                    bill.outstandingBalance = amount
                    bill.fieldMetadata["outstandingBalance"] = FieldExtractionMetadata(
                        fieldName: "Outstanding Balance",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                if let rawDate = firstCapture(in: line, pattern: #"\bby\s+([0-9OIlSB]{4}[\-/][0-9OIlSB]{2}[\-/][0-9OIlSB]{2})"#, group: 1) {
                    let (cleanDate, _) = normalizeDateToken(rawDate)
                    bill.outstandingDueDateRaw = cleanDate
                    bill.outstandingDueDate = BillExtractionDraft.parseFlexibleDate(cleanDate)
                }
                continue
            }

            // 5. Reading Date: 2026-09-30 (457)
            if line.range(of: #"^Reading\s*Date\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let rawDate = firstCapture(in: line, pattern: #"([0-9OIlSB]{4}[\-/][0-9OIlSB]{2}[\-/][0-9OIlSB]{2})"#, group: 1) {
                    let (cleanDate, wasCleaned) = normalizeDateToken(rawDate)
                    bill.readingDateRaw = cleanDate
                    bill.readingDate = BillExtractionDraft.parseFlexibleDate(cleanDate)
                    bill.fieldMetadata["readingDate"] = FieldExtractionMetadata(
                        fieldName: "Reading Date",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: wasCleaned
                    )
                }
                if let suffix = firstCapture(in: line, pattern: #"\(([A-Za-z0-9]+)\)"#, group: 1) {
                    bill.readingDateSuffix = suffix
                }
                continue
            }

            // 6. Reading: 10756 - 10678 = 78 Units
            if line.range(of: #"^Reading\s*[:\-]"#, options: [.regularExpression, .caseInsensitive]) != nil {
                let pattern = #"Reading\s*[:\-]?\s*([0-9OIlSB]+)\s*[\-–—]\s*([0-9OIlSB]+)\s*=\s*([0-9OIlSB]+)\s*(?:Units?|kWh)?"#
                let groups = allCaptures(in: line, pattern: pattern)
                if groups.count >= 4 {
                    let (r1Str, c1) = normalizeNumericToken(groups[1])
                    let (r2Str, c2) = normalizeNumericToken(groups[2])
                    let (uStr, c3) = normalizeNumericToken(groups[3])
                    if let r1 = Int(r1Str), let r2 = Int(r2Str) {
                        bill.currentReading = r1
                        bill.previousReading = r2
                    }
                    if let u = Int(uStr) {
                        bill.consumptionUnits = u
                    }
                    let wasCleaned = c1 || c2 || c3
                    bill.fieldMetadata["reading"] = FieldExtractionMetadata(
                        fieldName: "Meter Reading & Consumption",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: wasCleaned
                    )
                }
                continue
            }

            // 7. Charge: Rs. 1,588.00
            if line.range(of: #"^(?:Electricity\s+|Energy\s+)?Charge\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amount, cleaned) = extractDecimalCurrency(from: line) {
                    bill.energyCharge = amount
                    bill.fieldMetadata["energyCharge"] = FieldExtractionMetadata(
                        fieldName: "Energy Charge",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                continue
            }

            // 8. SSC Levy / SSCL Levy: Rs. 40.72
            if line.range(of: #"^(?:SSC|SSCL)\s*Levy\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amount, cleaned) = extractDecimalCurrency(from: line) {
                    bill.levyAmount = amount
                    bill.fieldMetadata["levyAmount"] = FieldExtractionMetadata(
                        fieldName: "SSCL / SSC Levy",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                continue
            }

            // 9. Monthly Bill: Rs. 1,628.72
            if line.range(of: #"^Monthly\s*Bill\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amount, cleaned) = extractDecimalCurrency(from: line) {
                    bill.monthlyBill = amount
                    bill.fieldMetadata["monthlyBill"] = FieldExtractionMetadata(
                        fieldName: "Monthly Bill",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                continue
            }

            // 10. Total Due: Rs. 2,415.79
            if line.range(of: #"^Total\s*Due\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amount, cleaned) = extractDecimalCurrency(from: line) {
                    bill.totalDue = amount
                    bill.fieldMetadata["totalDue"] = FieldExtractionMetadata(
                        fieldName: "Total Due",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: cleaned
                    )
                }
                continue
            }

            // 11. View e-Bill URL
            if line.lowercased().hasPrefix("http://") || line.lowercased().hasPrefix("https://") {
                if let urlPart = line.components(separatedBy: .whitespaces).first {
                    bill.billURL = urlPart
                }
            }
        }
    }

    // MARK: - Printed CEB / LECO / Standard Bill Parser
    private func parsePrintedOrStandardBill(lines: [RecognizedTextLine], into bill: inout ExtractedElectricityBill) {
        for (index, item) in lines.enumerated() {
            let line = item.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Provider fallback if still nil
            if bill.provider == nil {
                if line.localizedCaseInsensitiveContains("Ceylon Electricity Board") || line.localizedCaseInsensitiveContains("CEB") {
                    bill.provider = "Ceylon Electricity Board (CEB)"
                } else if line.localizedCaseInsensitiveContains("Lanka Electricity Company") || line.localizedCaseInsensitiveContains("LECO") {
                    bill.provider = "Lanka Electricity Company (LECO)"
                } else if line.localizedCaseInsensitiveContains("Electric") || line.localizedCaseInsensitiveContains("Power") || line.localizedCaseInsensitiveContains("Energy") {
                    bill.provider = line
                }
            }

            // Currency detection
            if line.contains("$") {
                bill.currency = "USD"
            } else if line.localizedCaseInsensitiveContains("Rs") || line.localizedCaseInsensitiveContains("LKR") {
                bill.currency = "LKR"
            }

            // Account Number
            if bill.accountNumber == nil,
               let acct = firstCapture(in: line, pattern: #"(?:Account\s*(?:No|Number|#)?|A\s*/?\s*C\s*No)\s*[:\-]?\s*([A-Z0-9\-]{6,16})"#, group: 1) {
                bill.accountNumber = acct
                bill.fieldMetadata["accountNumber"] = FieldExtractionMetadata(
                    fieldName: "Account Number",
                    rawLine: line,
                    confidence: item.confidence,
                    wasOCRCleaned: false
                )
            }

            // Tariff Category
            if bill.tariffCode == nil,
               let tariff = firstCapture(in: line, pattern: #"Tariff\s*(?:Category|Code)?\s*[:\-]?\s*([A-Z0-9\-]{1,6})"#, group: 1) {
                bill.tariffCode = tariff
            }

            // Customer Name
            if bill.customerName == nil,
               let name = firstCapture(in: line, pattern: #"(?:Customer\s*Name|Consumer\s*Name|Name)\s*[:\-]?\s*([A-Za-z\s\.]{3,40})"#, group: 1) {
                bill.customerName = name.trimmingCharacters(in: .whitespaces)
            }

            // Reading equation if present on printed bill
            if line.range(of: #"Reading\s*[:\-]?\s*[0-9OIlSB]+\s*[\-–—]\s*[0-9OIlSB]+\s*="#, options: [.regularExpression, .caseInsensitive]) != nil {
                let groups = allCaptures(in: line, pattern: #"([0-9OIlSB]+)\s*[\-–—]\s*([0-9OIlSB]+)\s*=\s*([0-9OIlSB]+)"#)
                if groups.count >= 4 {
                    bill.currentReading = Int(normalizeNumericToken(groups[1]).0)
                    bill.previousReading = Int(normalizeNumericToken(groups[2]).0)
                    bill.consumptionUnits = Int(normalizeNumericToken(groups[3]).0)
                }
            }

            // Explicit Previous & Current Meter Readings
            if bill.previousReading == nil,
               let prev = firstCapture(in: line, pattern: #"Previous\s*(?:Meter\s*)?Reading\s*[:\-]?\s*([0-9OIlSB]{3,8})"#, group: 1) {
                bill.previousReading = Int(normalizeNumericToken(prev).0)
            }
            if bill.currentReading == nil,
               let curr = firstCapture(in: line, pattern: #"(?:Current|Present)\s*(?:Meter\s*)?Reading\s*[:\-]?\s*([0-9OIlSB]{3,8})"#, group: 1) {
                bill.currentReading = Int(normalizeNumericToken(curr).0)
            }

            // Consumption (kWh / Units)
            if bill.consumptionUnits == nil {
                if let unitsStr = firstCapture(in: line, pattern: #"(?:Total\s*(?:kWh|Units)|Consumption|Units\s*Consumed|Units\s*Used)\s*[:\-]?\s*([0-9OIlSB]{1,6})\s*(?:kWh|Units)?"#, group: 1) {
                    bill.consumptionUnits = Int(normalizeNumericToken(unitsStr).0)
                    bill.fieldMetadata["consumptionUnits"] = FieldExtractionMetadata(
                        fieldName: "Consumption Units",
                        rawLine: line,
                        confidence: item.confidence,
                        wasOCRCleaned: false
                    )
                } else if let inlineKWh = firstCapture(in: line, pattern: #"\b([0-9]{1,6})\s*kWh\b"#, group: 1) {
                    bill.consumptionUnits = Int(inlineKWh)
                }
            }

            // Brought Forward / Previous Balance
            if bill.broughtForward == nil,
               line.range(of: #"(?:Brought\s*Forward|Previous\s*Balance|B/F|Arrears)"#, options: [.regularExpression, .caseInsensitive]) != nil,
               let (amt, cl) = extractDecimalCurrency(from: line) {
                bill.broughtForward = amt
                bill.fieldMetadata["broughtForward"] = FieldExtractionMetadata(fieldName: "Brought Forward", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
            }

            // Payments
            if bill.payments == nil,
               line.range(of: #"(?:Payments?\s*Received|Last\s*Payment|Payments?)"#, options: [.regularExpression, .caseInsensitive]) != nil,
               let (amt, cl) = extractDecimalCurrency(from: line) {
                bill.payments = amt
                bill.fieldMetadata["payments"] = FieldExtractionMetadata(fieldName: "Payments", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
            }

            // Outstanding Balance
            if bill.outstandingBalance == nil,
               line.range(of: #"Outstanding\s*(?:Balance|Amount)?"#, options: [.regularExpression, .caseInsensitive]) != nil,
               let (amt, cl) = extractDecimalCurrency(from: line) {
                bill.outstandingBalance = amt
                bill.fieldMetadata["outstandingBalance"] = FieldExtractionMetadata(fieldName: "Outstanding Balance", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
            }

            // Energy Charge
            if bill.energyCharge == nil,
               line.range(of: #"(?:Energy\s*Charge|Electricity\s*Charge|Usage\s*Charge|^Charge\b)"#, options: [.regularExpression, .caseInsensitive]) != nil,
               let (amt, cl) = extractDecimalCurrency(from: line) {
                bill.energyCharge = amt
                bill.fieldMetadata["energyCharge"] = FieldExtractionMetadata(fieldName: "Energy Charge", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
            }

            // Levies / Taxes
            if bill.levyAmount == nil,
               line.range(of: #"(?:SSC\s*Levy|SSCL\s*Levy|Tax\s*&\s*Levy|Levy)"#, options: [.regularExpression, .caseInsensitive]) != nil,
               let (amt, cl) = extractDecimalCurrency(from: line) {
                bill.levyAmount = amt
                bill.fieldMetadata["levyAmount"] = FieldExtractionMetadata(fieldName: "Levies", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
            }

            // Monthly Bill
            if bill.monthlyBill == nil,
               line.range(of: #"(?:Monthly\s*Bill|Current\s*Month\s*Charges|Total\s*Current\s*Bill)"#, options: [.regularExpression, .caseInsensitive]) != nil,
               let (amt, cl) = extractDecimalCurrency(from: line) {
                bill.monthlyBill = amt
                bill.fieldMetadata["monthlyBill"] = FieldExtractionMetadata(fieldName: "Monthly Bill", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
            }

            // Total Due
            if bill.totalDue == nil,
               line.range(of: #"(?:Total\s*Due|Total\s*Amount\s*Due|Amount\s*Payable|Total\s*Payable|Total\s*Amount)"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let (amt, cl) = extractDecimalCurrency(from: line) {
                    bill.totalDue = amt
                    bill.fieldMetadata["totalDue"] = FieldExtractionMetadata(fieldName: "Total Due", rawLine: line, confidence: item.confidence, wasOCRCleaned: cl)
                } else if index + 1 < lines.count, let (nextAmt, cl) = extractDecimalCurrency(from: lines[index + 1].text) {
                    bill.totalDue = nextAmt
                    bill.fieldMetadata["totalDue"] = FieldExtractionMetadata(fieldName: "Total Due", rawLine: lines[index + 1].text, confidence: lines[index + 1].confidence, wasOCRCleaned: cl)
                }
            }

            // Reading Date / Billing Date
            if bill.readingDateRaw == nil,
               let dateStr = firstCapture(in: line, pattern: #"(?:Reading\s*Date|Bill\s*Date|Billing\s*Date)\s*[:\-]?\s*([0-9]{4}[\-/][0-9]{2}[\-/][0-9]{2}|[0-9]{2}[\-/][0-9]{2}[\-/][0-9]{4})"#, group: 1) {
                bill.readingDateRaw = dateStr
                bill.readingDate = BillExtractionDraft.parseFlexibleDate(dateStr)
            }

            // Payment Due Date
            if bill.paymentDueDateRaw == nil,
               let dueStr = firstCapture(in: line, pattern: #"(?:Due\s*Date|Payment\s*Due)\s*[:\-]?\s*([0-9]{4}[\-/][0-9]{2}[\-/][0-9]{2}|[0-9]{2}[\-/][0-9]{2}[\-/][0-9]{4}|[A-Za-z]{3,9}\s+\d{1,2},?\s+\d{4})"#, group: 1) {
                bill.paymentDueDateRaw = dueStr
                bill.paymentDueDate = BillExtractionDraft.parseFlexibleDate(dueStr)
            }
        }
    }

    // MARK: - Context-Aware OCR Character Disambiguation & Helpers
    public func isLikelyCustomerName(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return false }
        let forbiddenPrefixes = [
            "a/c", "account", "b/f", "payment", "outstanding", "reading",
            "charge", "ssc", "monthly", "total", "view", "http", "ebill", "ceylon"
        ]
        let lower = trimmed.lowercased()
        if forbiddenPrefixes.contains(where: { lower.hasPrefix($0) || lower.contains("rs.") }) {
            return false
        }
        let hasLetters = trimmed.range(of: #"[A-Za-z]{2,}"#, options: .regularExpression) != nil
        let hasDigits = trimmed.range(of: #"\d"#, options: .regularExpression) != nil
        return hasLetters && !hasDigits
    }

    /// Corrects common OCR confusions (O->0, I/l->1, S->5, B->8) ONLY within isolated numeric/currency tokens.
    public func normalizeNumericToken(_ raw: String) -> (String, Bool) {
        var result = ""
        var changed = false
        for ch in raw {
            switch ch {
            case "O", "o":
                result.append("0"); changed = true
            case "I", "l", "|":
                result.append("1"); changed = true
            case "S", "s":
                result.append("5"); changed = true
            case "B":
                result.append("8"); changed = true
            default:
                result.append(ch)
            }
        }
        return (result, changed)
    }

    public func normalizeDateToken(_ raw: String) -> (String, Bool) {
        let (cleaned, changed) = normalizeNumericToken(raw)
        return (cleaned.replacingOccurrences(of: "/", with: "-"), changed)
    }

    public func extractDecimalCurrency(from line: String) -> (Decimal, Bool)? {
        let targetSlice: String
        if let colonRange = line.range(of: ":") {
            targetSlice = String(line[colonRange.upperBound...])
        } else {
            targetSlice = line
        }
        let pattern = #"(?:Rs\.?|LKR|\$|£)?\s*([0-9OIlSB]{1,3}(?:,[0-9OIlSB]{3})+|[0-9OIlSB]+)\.[0-9OIlSB]{2}"#
        guard let matchedToken = firstCapture(in: targetSlice, pattern: pattern, group: 0) else {
            return nil
        }
        let strippedPrefix = matchedToken
            .replacingOccurrences(of: "Rs.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Rs", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "LKR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let (normalized, wasCleaned) = normalizeNumericToken(strippedPrefix)
        guard let decimalValue = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        return (decimalValue, wasCleaned)
    }

    public func firstCapture(in text: String, pattern: String, group: Int) -> String? {
        let captures = allCaptures(in: text, pattern: pattern)
        guard captures.indices.contains(group) else { return nil }
        return captures[group]
    }

    public func allCaptures(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else {
            return []
        }
        return (0..<match.numberOfRanges).compactMap { idx in
            let range = match.range(at: idx)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else {
                return nil
            }
            return String(text[swiftRange])
        }
    }
}

// MARK: - 5. Decimal-Safe Financial & Meter Reading Validator
public final class ElectricityBillValidator: Sendable {
    public init() {}

    public func validate(_ bill: ExtractedElectricityBill) -> [BillValidationWarning] {
        var warnings: [BillValidationWarning] = []

        // 1. Required Identifying Fields Check
        if bill.accountNumber == nil || bill.accountNumber?.isEmpty == true {
            warnings.append(BillValidationWarning(
                fieldKey: "accountNumber",
                severity: .warning,
                title: "Missing Account Number",
                message: "Account number was not recognized. Please enter or verify it before saving.",
                expectedValue: nil,
                actualValue: nil
            ))
        }

        if bill.readingDate == nil && (bill.readingDateRaw == nil || bill.readingDateRaw?.isEmpty == true) {
            warnings.append(BillValidationWarning(
                fieldKey: "readingDate",
                severity: .warning,
                title: "Missing Reading Date",
                message: "Reading date could not be recognized. Please enter the billing/reading date.",
                expectedValue: nil,
                actualValue: nil
            ))
        }

        if bill.consumptionUnits == nil {
            warnings.append(BillValidationWarning(
                fieldKey: "consumptionUnits",
                severity: .warning,
                title: "Missing Consumption (kWh)",
                message: "Electricity consumption units were not detected.",
                expectedValue: nil,
                actualValue: nil
            ))
        }

        if bill.totalDue == nil && bill.monthlyBill == nil {
            warnings.append(BillValidationWarning(
                fieldKey: "totalDue",
                severity: .error,
                title: "Missing Bill Amount",
                message: "Neither Total Due nor Monthly Bill was recognized. Please enter the bill amount.",
                expectedValue: nil,
                actualValue: nil
            ))
        }

        // 2. Meter Reading Reconciliation: Current - Previous == Consumption
        if let current = bill.currentReading, let previous = bill.previousReading {
            if current < previous {
                warnings.append(BillValidationWarning(
                    fieldKey: "reading",
                    severity: .error,
                    title: "Inconsistent Meter Readings",
                    message: "Current meter reading (\(current)) is lower than previous reading (\(previous)).",
                    expectedValue: ">= \(previous)",
                    actualValue: "\(current)"
                ))
            } else {
                let calculatedUnits = current - previous
                if let extractedUnits = bill.consumptionUnits, extractedUnits != calculatedUnits {
                    warnings.append(BillValidationWarning(
                        fieldKey: "consumptionUnits",
                        severity: .warning,
                        title: "Meter Reading Discrepancy",
                        message: "Reading difference (\(current) - \(previous) = \(calculatedUnits) Units) does not match extracted consumption (\(extractedUnits) Units).",
                        expectedValue: "\(calculatedUnits)",
                        actualValue: "\(extractedUnits)"
                    ))
                }
            }
        }

        // 3. Balance Reconciliation: Brought Forward - Payments == Outstanding Balance
        if let bf = bill.broughtForward, let pay = bill.payments, let out = bill.outstandingBalance {
            let expectedOutstanding = bf - pay
            if expectedOutstanding != out {
                warnings.append(BillValidationWarning(
                    fieldKey: "outstandingBalance",
                    severity: .warning,
                    title: "Outstanding Balance Discrepancy",
                    message: "B/F (\(BillExtractionDraft.formatDecimal(bf))) - Payments (\(BillExtractionDraft.formatDecimal(pay))) = \(BillExtractionDraft.formatDecimal(expectedOutstanding)), but Outstanding is \(BillExtractionDraft.formatDecimal(out)).",
                    expectedValue: BillExtractionDraft.formatDecimal(expectedOutstanding),
                    actualValue: BillExtractionDraft.formatDecimal(out)
                ))
            }
        }

        // 4. Monthly Bill Reconciliation: Energy Charge + Levy == Monthly Bill
        if let charge = bill.energyCharge, let levy = bill.levyAmount, let monthly = bill.monthlyBill {
            let expectedMonthly = charge + levy
            if expectedMonthly != monthly {
                warnings.append(BillValidationWarning(
                    fieldKey: "monthlyBill",
                    severity: .warning,
                    title: "Monthly Bill Discrepancy",
                    message: "Charge (\(BillExtractionDraft.formatDecimal(charge))) + Levy (\(BillExtractionDraft.formatDecimal(levy))) = \(BillExtractionDraft.formatDecimal(expectedMonthly)), but Monthly Bill is \(BillExtractionDraft.formatDecimal(monthly)).",
                    expectedValue: BillExtractionDraft.formatDecimal(expectedMonthly),
                    actualValue: BillExtractionDraft.formatDecimal(monthly)
                ))
            }
        }

        // 5. Total Due Reconciliation: Outstanding + Monthly Bill == Total Due
        if let out = bill.outstandingBalance, let monthly = bill.monthlyBill, let total = bill.totalDue {
            let expectedTotal = out + monthly
            if expectedTotal != total {
                warnings.append(BillValidationWarning(
                    fieldKey: "totalDue",
                    severity: .warning,
                    title: "Total Due Discrepancy",
                    message: "Outstanding (\(BillExtractionDraft.formatDecimal(out))) + Monthly Bill (\(BillExtractionDraft.formatDecimal(monthly))) = \(BillExtractionDraft.formatDecimal(expectedTotal)), but Total Due is \(BillExtractionDraft.formatDecimal(total)).",
                    expectedValue: BillExtractionDraft.formatDecimal(expectedTotal),
                    actualValue: BillExtractionDraft.formatDecimal(total)
                ))
            }
        }

        // 6. Low OCR Confidence Field Warnings
        for (key, meta) in bill.fieldMetadata where meta.isLowConfidence {
            warnings.append(BillValidationWarning(
                fieldKey: key,
                severity: .info,
                title: "Verify \(meta.fieldName)",
                message: meta.wasOCRCleaned
                    ? "OCR disambiguation was applied to '\(meta.rawLine)'. Please confirm this value."
                    : "Low OCR confidence (\(Int(meta.confidence * 100))%) for \(meta.fieldName). Please verify.",
                expectedValue: nil,
                actualValue: nil
            ))
        }

        return warnings
    }
}

// MARK: - 6. Facade Service Integrating OCR, Parser, and Validator
public final class BillTextRecognitionService: @unchecked Sendable {
    public static let shared = BillTextRecognitionService()

    public let ocrService: ElectricityBillOCRService
    public let parser: ElectricityBillParser
    public let validator: ElectricityBillValidator

    public init(
        ocrService: ElectricityBillOCRService = ElectricityBillOCRService(),
        parser: ElectricityBillParser = ElectricityBillParser(),
        validator: ElectricityBillValidator = ElectricityBillValidator()
    ) {
        self.ocrService = ocrService
        self.parser = parser
        self.validator = validator
    }

    public func extractBillData(from image: UIImage) async throws -> BillExtractionDraft {
        let recognizedLines = try await ocrService.recognizeText(from: image)
        let extractedBill = parser.parse(lines: recognizedLines)
        return BillExtractionDraft(from: extractedBill)
    }

    public func extractBillData(fromPDF url: URL) async throws -> (UIImage, BillExtractionDraft) {
        let renderedImage = try ocrService.renderImage(fromPDF: url)
        let draft = try await extractBillData(from: renderedImage)
        return (renderedImage, draft)
    }

    public func parseRecognizedText(_ text: String) -> BillExtractionDraft {
        let extractedBill = parser.parse(rawText: text)
        return BillExtractionDraft(from: extractedBill)
    }

    /// Backward-compatibility helper for raw OCR string recognition
    public static func recognizeText(from image: UIImage) async throws -> String {
        let lines = try await shared.ocrService.recognizeText(from: image)
        return lines.map(\.text).joined(separator: "\n")
    }
}

// MARK: - Legacy / UI Bridge: ExtractedBillData
public struct ExtractedBillData: Equatable, Sendable {
    public var provider: String
    public var accountNumber: String
    public var tariffCategory: String?
    public var customerName: String?
    public var customerAddress: String?
    public var readingDate: String?
    public var billingPeriod: String
    public var dueDate: String?
    public var previousReading: String
    public var currentReading: String
    public var consumptionKwh: String
    public var currentCharge: String?
    public var fixedCharges: String?
    public var taxesAndLevies: String?
    public var monthlyBill: String?
    public var previousBalance: String?
    public var payments: String?
    public var outstandingBalance: String?
    public var totalAmountPayable: String
    public var ebillLink: String?
    public var rawText: String

    public var isMathConsistent: Bool
    public var validationMessages: [String]
    public var confidenceScore: Double

    public var billAmount: String {
        get {
            if !totalAmountPayable.isEmpty {
                return totalAmountPayable
            } else if let mb = monthlyBill, !mb.isEmpty {
                return mb
            }
            return "LKR 0.00"
        }
        set {
            totalAmountPayable = newValue
        }
    }

    public init(
        provider: String = "CEB",
        accountNumber: String = "",
        tariffCategory: String? = nil,
        customerName: String? = nil,
        customerAddress: String? = nil,
        readingDate: String? = nil,
        billingPeriod: String = "",
        dueDate: String? = nil,
        previousReading: String = "",
        currentReading: String = "",
        consumptionKwh: String = "",
        currentCharge: String? = nil,
        fixedCharges: String? = nil,
        taxesAndLevies: String? = nil,
        monthlyBill: String? = nil,
        previousBalance: String? = nil,
        payments: String? = nil,
        outstandingBalance: String? = nil,
        totalAmountPayable: String = "",
        ebillLink: String? = nil,
        rawText: String = "",
        isMathConsistent: Bool = true,
        validationMessages: [String] = [],
        confidenceScore: Double = 1.0
    ) {
        self.provider = provider
        self.accountNumber = accountNumber
        self.tariffCategory = tariffCategory
        self.customerName = customerName
        self.customerAddress = customerAddress
        self.readingDate = readingDate
        self.billingPeriod = billingPeriod
        self.dueDate = dueDate
        self.previousReading = previousReading
        self.currentReading = currentReading
        self.consumptionKwh = consumptionKwh
        self.currentCharge = currentCharge
        self.fixedCharges = fixedCharges
        self.taxesAndLevies = taxesAndLevies
        self.monthlyBill = monthlyBill
        self.previousBalance = previousBalance
        self.payments = payments
        self.outstandingBalance = outstandingBalance
        self.totalAmountPayable = totalAmountPayable
        self.ebillLink = ebillLink
        self.rawText = rawText
        self.isMathConsistent = isMathConsistent
        self.validationMessages = validationMessages
        self.confidenceScore = confidenceScore
    }

    public init(from draft: BillExtractionDraft) {
        let hasErrors = draft.validationWarnings.contains { $0.severity == .error }
        let msgs = draft.validationWarnings.map { "\($0.title): \($0.message)" }

        self.init(
            provider: draft.providerName.isEmpty ? "CEB" : draft.providerName,
            accountNumber: draft.accountNumber,
            tariffCategory: draft.tariffCategory.isEmpty ? nil : draft.tariffCategory,
            customerName: draft.customerName.isEmpty ? nil : draft.customerName,
            customerAddress: nil,
            readingDate: draft.readingDate.isEmpty ? nil : draft.readingDate,
            billingPeriod: draft.billingMonth.isEmpty ? "Current Period" : draft.billingMonth,
            dueDate: draft.dueDate.isEmpty ? nil : draft.dueDate,
            previousReading: draft.previousReading.isEmpty ? "" : "\(draft.previousReading) kWh",
            currentReading: draft.currentReading.isEmpty ? "" : "\(draft.currentReading) kWh",
            consumptionKwh: draft.totalKWh.isEmpty ? "" : "\(draft.totalKWh) kWh",
            currentCharge: draft.electricityCharge.isEmpty ? nil : "Rs. \(draft.electricityCharge)",
            fixedCharges: nil,
            taxesAndLevies: draft.sscLevy.isEmpty ? nil : "Rs. \(draft.sscLevy)",
            monthlyBill: draft.monthlyBill.isEmpty ? nil : "Rs. \(draft.monthlyBill)",
            previousBalance: draft.previousBalance.isEmpty ? nil : "Rs. \(draft.previousBalance)",
            payments: draft.payments.isEmpty ? nil : "Rs. \(draft.payments)",
            outstandingBalance: draft.outstandingBalance.isEmpty ? nil : "Rs. \(draft.outstandingBalance)",
            totalAmountPayable: draft.totalAmount.isEmpty ? (draft.monthlyBill.isEmpty ? "" : "Rs. \(draft.monthlyBill)") : "Rs. \(draft.totalAmount)",
            ebillLink: draft.billURL.isEmpty ? nil : draft.billURL,
            rawText: draft.rawExtractedText,
            isMathConsistent: !hasErrors,
            validationMessages: msgs,
            confidenceScore: Double(draft.extractionConfidence)
        )
    }

    public static let sample = ExtractedBillData(
        provider: "CEB",
        accountNumber: "5410264908",
        tariffCategory: "D1",
        customerName: "R RANJITH",
        customerAddress: "Colombo, Sri Lanka",
        readingDate: "2026-09-30",
        billingPeriod: "01 Sep – 30 Sep 2026",
        dueDate: "2026-09-17",
        previousReading: "10,678 kWh",
        currentReading: "10,756 kWh",
        consumptionKwh: "78 kWh",
        currentCharge: "Rs. 1,588.00",
        fixedCharges: "Rs. 0.00",
        taxesAndLevies: "Rs. 40.72",
        monthlyBill: "Rs. 1,628.72",
        previousBalance: "Rs. 2,987.07",
        payments: "Rs. 2,200.00",
        outstandingBalance: "Rs. 787.07",
        totalAmountPayable: "Rs. 2,415.79",
        ebillLink: "https://ebill.edl.lk/v1/NTQxMDI2NDkwOCo0NTcqNTg2",
        rawText: "Sample CEB e-Bill",
        isMathConsistent: true,
        validationMessages: [
            "Meter readings verified (10756 - 10678 = 78 Units)",
            "Charge + SSC Levy equals Monthly Bill (1588.00 + 40.72 = 1628.72)",
            "Outstanding + Monthly Bill equals Total Due (787.07 + 1628.72 = 2415.79)"
        ],
        confidenceScore: 0.98
    )

    public static func parse(from rawText: String) -> ExtractedBillData {
        let draft = BillTextRecognitionService.shared.parseRecognizedText(rawText)
        return ExtractedBillData(from: draft)
    }

    public static func cleanNumericString(from input: String) -> String {
        let sanitized = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "kWh", with: "")
            .replacingOccurrences(of: "KWH", with: "")
            .replacingOccurrences(of: "kwh", with: "")
            .replacingOccurrences(of: "Units", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Unit", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "LKR", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let numberPattern = #"[-+]?\d+(?:\.\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: numberPattern),
              let match = regex.firstMatch(in: sanitized, range: NSRange(sanitized.startIndex..., in: sanitized)) else {
            return "0"
        }

        return (sanitized as NSString).substring(with: match.range)
    }
}
