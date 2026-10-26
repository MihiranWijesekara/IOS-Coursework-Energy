//
//  EnergyLensWidget.swift
//  ios-final-coursework
//
//  WidgetKit Home Screen Extension for EnergyLens
//  Displays "THIS MONTH" consumption card and "Next Month Core ML" forecast
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Entry
public struct EnergyWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: EnergyWidgetSnapshot

    public init(date: Date = Date(), snapshot: EnergyWidgetSnapshot = .sample) {
        self.date = date
        self.snapshot = snapshot
    }
}

// MARK: - Timeline Provider
public struct EnergyLensWidgetProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> EnergyWidgetEntry {
        EnergyWidgetEntry(date: Date(), snapshot: .sample)
    }

    public func getSnapshot(in context: Context, completion: @escaping (EnergyWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot()
        completion(EnergyWidgetEntry(date: Date(), snapshot: snapshot))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<EnergyWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot()
        let entry = EnergyWidgetEntry(date: Date(), snapshot: snapshot)
        // Refresh every 30 minutes or when app calls WidgetCenter.shared.reloadAllTimelines()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views
public struct EnergyLensWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public var entry: EnergyWidgetEntry

    public init(entry: EnergyWidgetEntry) {
        self.entry = entry
    }

    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.38, blue: 0.28),
                Color(red: 0.22, green: 0.58, blue: 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumWidgetView
            default:
                smallWidgetView
            }
        }
        .containerBackground(for: .widget) {
            gradientBackground
        }
    }

    // MARK: - System Medium Layout
    private var mediumWidgetView: some View {
        HStack(alignment: .center, spacing: 14) {
            // Left Column: THIS MONTH Card
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                    Text("THIS MONTH · \(entry.snapshot.billingMonth)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        .lineLimit(1)
                        .tracking(0.5)
                }

                Spacer(minLength: 2)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(entry.snapshot.currentKWh))")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("kWh")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                }

                Text("\(entry.snapshot.currency) \(String(format: "%.2f", entry.snapshot.currentBillAmount))")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Spacer(minLength: 2)

                Text("Imported bill · \(entry.snapshot.town)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right-hand Glass Card: NEXT MONTH CORE ML FORECAST
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.35))
                    Text("NEXT MONTH · \(entry.snapshot.usedCoreML ? "CORE ML" : "FORECAST")")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.96, blue: 0.90))
                        .tracking(0.4)
                }

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(entry.snapshot.predictedNextKWh))")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("kWh")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }

                Text("Est. \(entry.snapshot.currency) \(Int(entry.snapshot.predictedNextCost))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "thermometer.sun.fill")
                        .font(.system(size: 9))
                    Text("\(Int(entry.snapshot.temperatureC))°C · \(entry.snapshot.town)")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.75))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.16))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
        }
        .padding(14)
    }

    // MARK: - System Small Layout
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("THIS MONTH · \(entry.snapshot.billingMonth)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                .lineLimit(1)
                .tracking(0.4)

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(entry.snapshot.currentKWh))")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("kWh")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }

            Text("\(entry.snapshot.currency) \(String(format: "%.2f", entry.snapshot.currentBillAmount))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Spacer(minLength: 2)

            // Mini Core ML badge pill
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.35))
                Text("Next: \(Int(entry.snapshot.predictedNextKWh)) kWh · \(entry.snapshot.currency)\(Int(entry.snapshot.predictedNextCost))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.18))
            .cornerRadius(8)
        }
        .padding(12)
    }
}

// MARK: - Widget Definition
public struct EnergyLensWidget: Widget {
    public let kind: String = "EnergyLensWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnergyLensWidgetProvider()) { entry in
            EnergyLensWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("EnergyLens Summary")
        .description("Track current electricity consumption and next month Core ML prediction.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
