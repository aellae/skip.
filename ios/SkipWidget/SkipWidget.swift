//
//  SkipWidget.swift
//  SkipWidget
//
//  Created by Elena Tarantino on 23/09/2026.
//
//  Reads this-month saved/spent totals written by the Flutter app (see
//  lib/core/home_widget/home_widget_service.dart) into the shared App Group,
//  and mirrors the two SKIP aesthetics (lib/core/constants/app_colors.dart /
//  lib/core/theme/theme_provider.dart) since this extension has no access to
//  the app's ThemeData.

import WidgetKit
import SwiftUI

private let appGroupId = "group.com.skip.finance"

enum SkipAesthetic: String {
    case minimal
    case y2k

    var logoText: String {
        switch self {
        case .minimal: return "skip."
        case .y2k: return "SKIP!"
        }
    }

    var background: Color {
        switch self {
        case .minimal: return Color(red: 0xFD / 255, green: 0xFB / 255, blue: 0xF7 / 255)
        case .y2k: return Color(red: 0x24 / 255, green: 0x1A / 255, blue: 0x33 / 255)
        }
    }

    var textColor: Color {
        switch self {
        case .minimal: return Color(red: 0x2C / 255, green: 0x30 / 255, blue: 0x2E / 255)
        case .y2k: return Color(red: 0xE0 / 255, green: 0xE0 / 255, blue: 0xE0 / 255)
        }
    }

    var savedColor: Color {
        switch self {
        case .minimal: return Color(red: 0x5C / 255, green: 0x7A / 255, blue: 0x5A / 255)
        case .y2k: return Color(red: 0x00 / 255, green: 0xE5 / 255, blue: 0xA0 / 255)
        }
    }

    var spentColor: Color {
        switch self {
        case .minimal: return Color(red: 0xA3 / 255, green: 0x56 / 255, blue: 0x56 / 255)
        case .y2k: return Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x4A / 255)
        }
    }
}

/// Ports the two currency conventions from `currency_formatter.dart`'s
/// `formatCurrency`: USD is `$1,234.56` (prefix, comma thousands, dot
/// decimal); EUR is `1.234,56 €` (suffix, dot thousands, comma decimal).
private func formatCurrency(_ value: Double, currencyCode: String) -> String {
    let isEuro = currencyCode.lowercased() == "eur"
    let isNegative = value < 0
    let fixed = String(format: "%.2f", abs(value))
    let parts = fixed.split(separator: ".")
    let digits = Array(parts[0])
    let cents = parts.count > 1 ? String(parts[1]) : "00"

    let thousandsSeparator = isEuro ? "." : ","
    var grouped = ""
    for (index, digit) in digits.enumerated() {
        let distanceFromEnd = digits.count - index
        if index > 0 && distanceFromEnd % 3 == 0 {
            grouped.append(thousandsSeparator)
        }
        grouped.append(digit)
    }

    let sign = isNegative ? "-" : ""
    return isEuro ? "\(sign)\(grouped),\(cents) €" : "\(sign)$\(grouped).\(cents)"
}

struct SkipWidgetEntry: TimelineEntry {
    let date: Date
    let saved: Double
    let spent: Double
    let currencyCode: String
    let aesthetic: SkipAesthetic
}

struct SkipWidgetProvider: TimelineProvider {
    private func currentEntry() -> SkipWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let aesthetic =
            SkipAesthetic(rawValue: defaults?.string(forKey: "aesthetic") ?? "") ?? .minimal
        return SkipWidgetEntry(
            date: Date(),
            saved: defaults?.double(forKey: "saved") ?? 0,
            spent: defaults?.double(forKey: "spent") ?? 0,
            currencyCode: defaults?.string(forKey: "currencyCode") ?? "usd",
            aesthetic: aesthetic
        )
    }

    func placeholder(in context: Context) -> SkipWidgetEntry {
        SkipWidgetEntry(date: Date(), saved: 120, spent: 45, currencyCode: "usd", aesthetic: .minimal)
    }

    func getSnapshot(in context: Context, completion: @escaping (SkipWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SkipWidgetEntry>) -> Void) {
        // The app pushes a fresh entry (via WidgetCenter.reloadTimelines) every
        // time totals actually change; this daily fallback only exists so the
        // "this month" bucket still rolls over at midnight if the app isn't
        // opened around the month boundary.
        let nextMidnight =
            Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) ?? Date().addingTimeInterval(86400)
        let timeline = Timeline(entries: [currentEntry()], policy: .after(nextMidnight))
        completion(timeline)
    }
}

struct SkipWidgetEntryView: View {
    var entry: SkipWidgetProvider.Entry

    private var savedText: String { formatCurrency(entry.saved, currencyCode: entry.currencyCode) }
    private var spentText: String { formatCurrency(entry.spent, currencyCode: entry.currencyCode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.aesthetic.logoText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(entry.aesthetic.textColor.opacity(0.6))

            Spacer(minLength: 0)

            statRow(label: "Saved", value: savedText, color: entry.aesthetic.savedColor)
            statRow(label: "Spent", value: spentText, color: entry.aesthetic.spentColor)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(entry.aesthetic.background, for: .widget)
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(entry.aesthetic.textColor.opacity(0.5))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
}

struct SkipWidget: Widget {
    let kind: String = "SkipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SkipWidgetProvider()) { entry in
            SkipWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Skip! This Month")
        .description("This month's saved vs. spent totals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SkipWidget()
} timeline: {
    SkipWidgetEntry(date: .now, saved: 120, spent: 45, currencyCode: "usd", aesthetic: .minimal)
    SkipWidgetEntry(date: .now, saved: 340, spent: 210, currencyCode: "eur", aesthetic: .y2k)
}
