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

    /// Image set in this extension's Assets.xcassets, generated from the
    /// matching transparent logo in assets/images/.
    var logoImageName: String {
        switch self {
        case .minimal: return "SkipLogo"
        case .y2k: return "SkipLogoY2K"
        }
    }

    /// Text wordmark for the lock-screen families, where the system tints
    /// everything monochrome and the logo image would render as a flat blob.
    var logoText: String {
        switch self {
        case .minimal: return "Skip!"
        case .y2k: return "Skip!"
        }
    }

    /// Mirrors each theme's card surface: a warm paper fade for "Skip!",
    /// a deep violet night for "Skip!" (glows are layered on in the view).
    var backgroundGradient: LinearGradient {
        switch self {
        case .minimal:
            return LinearGradient(
                colors: [Color(hex: 0xFDFBF7), Color(hex: 0xF3ECE1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .y2k:
            return LinearGradient(
                colors: [Color(hex: 0x2B1D3E), Color(hex: 0x181022)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var textColor: Color {
        switch self {
        case .minimal: return Color(hex: 0x2C302E)
        case .y2k: return Color(hex: 0xE0E0E0)
        }
    }

    var savedColor: Color {
        switch self {
        case .minimal: return Color(hex: 0x5C7A5A)
        case .y2k: return Color(hex: 0x00E5FF)
        }
    }

    var spentColor: Color {
        switch self {
        case .minimal: return Color(hex: 0xA35656)
        case .y2k: return Color(hex: 0xFF5FC8)
        }
    }

    /// Empty split-bar track, shown when nothing's been logged this month.
    var trackColor: Color { textColor.opacity(self == .minimal ? 0.08 : 0.14) }

    /// System stand-ins for the app's bundled faces (the extension doesn't
    /// ship them): serif echoes Playfair Display, heavy rounded echoes
    /// Titan One.
    func valueFont(size: CGFloat) -> Font {
        switch self {
        case .minimal: return .system(size: size, weight: .semibold, design: .serif)
        case .y2k: return .system(size: size, weight: .heavy, design: .rounded)
        }
    }

    var labelFont: Font {
        switch self {
        case .minimal: return .system(size: 10, weight: .medium)
        case .y2k: return .system(size: 10, weight: .bold, design: .rounded)
        }
    }

    /// The motto matches each theme's voice: a quiet italic serif aside for
    /// "Skip!", a loud rounded shout for "Skip!".
    func mottoFont(size: CGFloat) -> Font {
        switch self {
        case .minimal: return .system(size: size, weight: .regular, design: .serif).italic()
        case .y2k: return .system(size: size, weight: .bold, design: .rounded)
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
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
    var savedLabel = "Saved"
    var spentLabel = "Spent"
    /// Today's line for the medium widget, already translated and in the
    /// aesthetic's voice (see `mottosMinimal`/`mottosY2k` in
    /// app_strings.dart).
    var motto = "Want it, or want it today?"
}

/// Picks one motto per calendar day, so the line changes at midnight (when
/// the timeline below refreshes) without the app being opened. Must stay in
/// sync with `mottoOfTheDay` in lib/core/utils/motto_picker.dart, so the
/// widget and the app's Home screen show the same line: both index by whole
/// days since 1970-01-01 for the local Gregorian date.
private func mottoOfTheDay(_ mottos: [String], on date: Date) -> String? {
    guard !mottos.isEmpty else { return nil }
    let local = Calendar(identifier: .gregorian)
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    let parts = local.dateComponents([.year, .month, .day], from: date)
    guard let midnightUTC = utc.date(from: parts) else { return mottos[0] }
    let day = Int(midnightUTC.timeIntervalSince1970 / 86400)
    return mottos[day % mottos.count]
}

struct SkipWidgetProvider: TimelineProvider {
    private func currentEntry() -> SkipWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let aesthetic =
            SkipAesthetic(rawValue: defaults?.string(forKey: "aesthetic") ?? "") ?? .minimal
        let now = Date()
        let saved = defaults?.double(forKey: "saved") ?? 0
        let spent = defaults?.double(forKey: "spent") ?? 0
        var entry = SkipWidgetEntry(
            date: now,
            saved: saved,
            spent: spent,
            currencyCode: defaults?.string(forKey: "currencyCode") ?? "usd",
            aesthetic: aesthetic
        )
        if let label = defaults?.string(forKey: "savedLabel") { entry.savedLabel = label }
        if let label = defaults?.string(forKey: "spentLabel") { entry.spentLabel = label }
        let mottos = (defaults?.string(forKey: "mottos") ?? "")
            .split(separator: "\n")
            .map(String.init)
        let emptyMotto = defaults?.string(forKey: "mottoEmpty")
        if saved == 0 && spent == 0, let emptyMotto {
            entry.motto = emptyMotto
        } else if let motto = mottoOfTheDay(mottos, on: now) {
            entry.motto = motto
        }
        return entry
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
        // opened around the month boundary, and today's motto changes daily.
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
    @Environment(\.widgetFamily) private var family
    var entry: SkipWidgetProvider.Entry

    private var aesthetic: SkipAesthetic { entry.aesthetic }
    private var savedText: String { formatCurrency(entry.saved, currencyCode: entry.currencyCode) }
    private var spentText: String { formatCurrency(entry.spent, currencyCode: entry.currencyCode) }

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineLayout
                .containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            rectangularLayout
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .containerBackground(for: .widget) { Color.clear }
        case .systemMedium:
            mediumLayout
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .containerBackground(for: .widget) { background }
        default:
            smallLayout
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .containerBackground(for: .widget) { background }
        }
    }

    /// Lock screen, above the clock: a single line of text. Falls back to
    /// the bare amounts when the labelled version doesn't fit. The whole
    /// line is privacy-sensitive since it's mostly amounts.
    private var inlineLayout: some View {
        ViewThatFits {
            Text("\(entry.savedLabel) \(savedText) · \(entry.spentLabel) \(spentText)")
            Text("\(aesthetic.logoText) \(savedText) · \(spentText)")
        }
        .privacySensitive()
    }

    /// Lock screen, below the clock. The system renders it monochrome, so
    /// saved/spent are told apart by their labels rather than theme colors;
    /// the wordmark and values are marked accentable for tinted modes, and
    /// the values are privacy-sensitive so iOS redacts them while locked.
    /// Today's motto doesn't fit here at a readable size; it has its own
    /// lock-screen widget (`SkipMottoWidget`).
    private var rectangularLayout: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline) {
                Text(aesthetic.logoText)
                    .font(aesthetic.valueFont(size: 15))
                    .widgetAccentable()
                Spacer(minLength: 4)
                Text(entry.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            accessoryStat(label: entry.savedLabel, value: savedText)
            accessoryStat(label: entry.spentLabel, value: spentText)
        }
    }

    private func accessoryStat(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .widgetAccentable()
                .privacySensitive()
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(monthStyle: .abbreviated, maxLogoHeight: 40)
                .layoutPriority(1)
            Spacer(minLength: 6)
            VStack(alignment: .leading, spacing: 6) {
                stat(label: entry.savedLabel, value: savedText, color: aesthetic.savedColor, size: 20)
                stat(label: entry.spentLabel, value: spentText, color: aesthetic.spentColor, size: 20)
            }
            splitBar.padding(.top, 10)
        }
    }

    /// Two columns: brand and today's motto on the left, the month's
    /// numbers on the right.
    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Image(aesthetic.logoImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 48, alignment: .topLeading)
                    .widgetAccentable()
                    .layoutPriority(1)
                // Starts at stat-value size and fills the space under the
                // logo, shrinking only as far as a long line (or a long
                // translation) needs; bottom-aligned so it sits level with
                // the split bar.
                Text(entry.motto)
                    .font(aesthetic.mottoFont(size: 22))
                    .foregroundStyle(aesthetic.textColor.opacity(0.85))
                    .lineLimit(4)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    monthText(style: .wide)
                }
                Spacer(minLength: 4)
                VStack(alignment: .leading, spacing: 6) {
                    stat(label: entry.savedLabel, value: savedText, color: aesthetic.savedColor, size: 22)
                    stat(label: entry.spentLabel, value: spentText, color: aesthetic.spentColor, size: 22)
                }
                splitBar.padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// The logo grows into whatever height the stats leave free, up to
    /// `maxLogoHeight` (the image sets are rendered for 48pt), so it's as big
    /// as possible without pushing the totals out of a small widget.
    private func header(
        monthStyle: Date.FormatStyle.Symbol.Month,
        maxLogoHeight: CGFloat
    ) -> some View {
        HStack(alignment: .top) {
            Image(aesthetic.logoImageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: maxLogoHeight, alignment: .topLeading)
                .widgetAccentable()
            Spacer(minLength: 4)
            monthText(style: monthStyle)
        }
    }

    private func monthText(style: Date.FormatStyle.Symbol.Month) -> some View {
        Text(entry.date.formatted(.dateTime.month(style)).uppercased())
            .font(aesthetic.labelFont)
            .tracking(1.2)
            .foregroundStyle(aesthetic.textColor.opacity(0.5))
            .lineLimit(1)
    }

    private func stat(label: String, value: String, color: Color, size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label.uppercased())
                    .font(aesthetic.labelFont)
                    .tracking(1.2)
                    .foregroundStyle(aesthetic.textColor.opacity(0.55))
            }
            Text(value)
                .font(aesthetic.valueFont(size: size))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
                .widgetAccentable()
        }
    }

    /// Saved vs. spent share of this month's decisions, by amount.
    private var splitBar: some View {
        let total = max(entry.saved, 0) + max(entry.spent, 0)
        let savedShare = total > 0 ? max(entry.saved, 0) / total : 0
        return GeometryReader { proxy in
            let gap: CGFloat = total > 0 && savedShare > 0 && savedShare < 1 ? 3 : 0
            let savedWidth = (proxy.size.width - gap) * savedShare
            HStack(spacing: gap) {
                if total == 0 {
                    Capsule().fill(aesthetic.trackColor)
                } else {
                    if savedShare > 0 {
                        Capsule().fill(aesthetic.savedColor).frame(width: savedWidth)
                    }
                    if savedShare < 1 {
                        Capsule().fill(aesthetic.spentColor)
                    }
                }
            }
        }
        .frame(height: 6)
        .widgetAccentable()
    }

    @ViewBuilder
    private var background: some View {
        switch aesthetic {
        case .minimal:
            aesthetic.backgroundGradient
        case .y2k:
            ZStack {
                aesthetic.backgroundGradient
                RadialGradient(
                    colors: [Color(hex: 0xFF007F).opacity(0.35), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 140
                )
                RadialGradient(
                    colors: [Color(hex: 0xB026FF).opacity(0.28), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            }
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
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

/// Lock-screen-only companion: the app's wordmark over today's motto, large
/// enough to read; the longest translations (~55 characters) fit in three
/// lines.
struct SkipMottoWidgetEntryView: View {
    var entry: SkipWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.aesthetic.logoText)
                .font(entry.aesthetic.valueFont(size: 14))
                .widgetAccentable()
            Text(entry.motto)
                .font(entry.aesthetic.mottoFont(size: 16))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct SkipMottoWidget: Widget {
    let kind: String = "SkipMottoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SkipWidgetProvider()) { entry in
            SkipMottoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Skip! Motto")
        .description("Today's motto.")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    SkipWidget()
} timeline: {
    SkipWidgetEntry(date: .now, saved: 120, spent: 45, currencyCode: "usd", aesthetic: .minimal)
    SkipWidgetEntry(date: .now, saved: 340, spent: 210, currencyCode: "eur", aesthetic: .y2k)
    SkipWidgetEntry(date: .now, saved: 0, spent: 0, currencyCode: "usd", aesthetic: .minimal)
}

#Preview(as: .systemMedium) {
    SkipWidget()
} timeline: {
    SkipWidgetEntry(date: .now, saved: 1240.5, spent: 385, currencyCode: "usd", aesthetic: .minimal)
    SkipWidgetEntry(
        date: .now, saved: 340, spent: 2210, currencyCode: "eur", aesthetic: .y2k,
        savedLabel: "Risparmiato", spentLabel: "Speso", motto: "Carrello abbandonato. Iconico."
    )
}

#Preview(as: .accessoryRectangular) {
    SkipWidget()
} timeline: {
    SkipWidgetEntry(date: .now, saved: 1240.5, spent: 385, currencyCode: "usd", aesthetic: .minimal)
    SkipWidgetEntry(
        date: .now, saved: 340, spent: 2210, currencyCode: "eur", aesthetic: .y2k,
        savedLabel: "Risparmiato", spentLabel: "Speso"
    )
}

#Preview(as: .accessoryInline) {
    SkipWidget()
} timeline: {
    SkipWidgetEntry(date: .now, saved: 120, spent: 45, currencyCode: "usd", aesthetic: .minimal)
    SkipWidgetEntry(
        date: .now, saved: 1340, spent: 2210, currencyCode: "eur", aesthetic: .y2k,
        savedLabel: "Risparmiato", spentLabel: "Speso"
    )
}

#Preview("Motto", as: .accessoryRectangular, widget: { SkipMottoWidget() }) {
    SkipWidgetEntry(
        date: .now, saved: 0, spent: 0, currencyCode: "eur", aesthetic: .minimal,
        motto: "Essere ricchi è uno stato mentale. E un salvadanaio."
    )
    SkipWidgetEntry(
        date: .now, saved: 0, spent: 0, currencyCode: "usd", aesthetic: .y2k,
        motto: "Rich is a mindset. And a savings account."
    )
}
