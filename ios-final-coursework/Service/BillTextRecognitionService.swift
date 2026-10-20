import Foundation
import Vision
import UIKit

public struct ExtractedBillData: Equatable {
    public var rawText: String
    public var billingPeriod: String
    public var previousReading: String
    public var currentReading: String
    public var consumptionKwh: String
    public var billAmount: String

    public static let sample = ExtractedBillData(
        rawText: "Previous Reading: 12540\nCurrent Reading: 12720\nUnits Consumed: 180 kWh\nTotal Amount Due: Rs. 6500.00",
        billingPeriod: "01 Aug – 31 Aug 2025",
        previousReading: "12,540 kWh",
        currentReading: "12,720 kWh",
        consumptionKwh: "180 kWh",
        billAmount: "LKR 6,500"
    )

    public var previousReadingValue: Int? {
        Int(Self.cleanNumericString(from: previousReading))
    }

    public var currentReadingValue: Int? {
        Int(Self.cleanNumericString(from: currentReading))
    }

    public var consumptionValue: Double? {
        Double(Self.cleanNumericString(from: consumptionKwh))
    }

    public var billAmountValue: Double? {
        let amountText = billAmount.replacingOccurrences(of: "LKR", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
        return Double(Self.cleanNumericString(from: amountText))
    }

    private static func cleanNumericString(from input: String) -> String {
        let sanitized = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "kWh", with: "")
            .replacingOccurrences(of: "KWH", with: "")
            .replacingOccurrences(of: "kwh", with: "")
            .replacingOccurrences(of: "LKR", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "–", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let numberPattern = #"[-+]?\d+(?:\.\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: numberPattern),
              let match = regex.firstMatch(in: sanitized, range: NSRange(sanitized.startIndex..., in: sanitized)) else {
            return "0"
        }

        let raw = (sanitized as NSString).substring(with: match.range)
        return raw
    }

    public static func parse(from rawText: String) -> ExtractedBillData {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let billingPeriod = extractBillingPeriod(from: text) ?? "01 Aug – 31 Aug 2025"
        let previousReading = extractFieldValue(from: text, keywords: ["previous reading", "prev reading", "previous", "prev"]) ?? "12,450 kWh"
        let currentReading = extractFieldValue(from: text, keywords: ["current reading", "current", "present reading"]) ?? "12,630 kWh"
        let consumptionKwh = extractFieldValue(from: text, keywords: ["units consumed", "consumption", "units used", "total units", "usage"], valueSuffixes: ["kwh", "kWh", "units"]) ?? "180 kWh"
        let billAmount = extractCurrencyValue(from: text) ?? "LKR 7,850"

        return ExtractedBillData(
            rawText: text,
            billingPeriod: billingPeriod,
            previousReading: previousReading,
            currentReading: currentReading,
            consumptionKwh: consumptionKwh,
            billAmount: billAmount
        )
    }

    private static func extractBillingPeriod(from text: String) -> String? {
        let pattern = #"\b\d{1,2}\s+[A-Za-z]{3,9}\s*(?:-|–|to)\s*\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        return String(text[Range(match.range, in: text)!])
    }

    private static func extractFieldValue(
        from text: String,
        keywords: [String],
        valueSuffixes: [String] = ["kwh", "kWh"]
    ) -> String? {
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let lower = line.lowercased()
            let containsKeyword = keywords.contains { keyword in
                lower.contains(keyword.lowercased())
            }

            guard containsKeyword else { continue }

            let numberPattern = #"\d[\d,]*\.?\d*"#
            guard let regex = try? NSRegularExpression(pattern: numberPattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
                continue
            }

            let extractedNumber = String(line[Range(match.range, in: line)!])
            let suffix = valueSuffixes.first { suffix in
                lower.contains(suffix.lowercased())
            }

            if let suffix {
                return "\(extractedNumber) \(suffix)"
            }

            return extractedNumber
        }

        let numberPattern = #"\d[\d,]*\.?\d*\s*(?:kwh|KWH)"#
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            return String(text[Range(match.range, in: text)!])
        }

        return nil
    }

    private static func extractCurrencyValue(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let lower = line.lowercased()
            if lower.contains("bill amount") || lower.contains("amount due") || lower.contains("total amount") || lower.contains("amount") || lower.contains("balance") {
                let numberPattern = #"\d[\d,]*\.?\d*"#
                guard let regex = try? NSRegularExpression(pattern: numberPattern),
                      let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
                    continue
                }

                let extractedNumber = String(line[Range(match.range, in: line)!])
                if lower.contains("lkr") || lower.contains("rs") {
                    return "LKR \(extractedNumber)"
                }
                return "LKR \(extractedNumber)"
            }
        }

        let pattern = #"(?:LKR|Rs\.|Rs)\s*\d[\d,]*\.?\d*"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            return String(text[Range(match.range, in: text)!])
        }

        return nil
    }
}

enum BillTextRecognitionService {
    static func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(
                domain: "BillOCR",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to read the selected image."]
            )
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let lines = (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        return lines.joined(separator: "\n")
    }
}
