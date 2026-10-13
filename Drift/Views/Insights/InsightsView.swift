import SwiftUI
import Charts

private struct DayStat: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Double
}

private struct ShareStat: Identifiable {
    let id: String
    let scape: Soundscape
    let minutes: Double
}

struct InsightsView: View {
    @State private var grown = false
    @State private var selectedDay: String?
    @State private var range = 0

    private let week: [DayStat] = [
        .init(day: "Mon", minutes: 42), .init(day: "Tue", minutes: 65), .init(day: "Wed", minutes: 38),
        .init(day: "Thu", minutes: 80), .init(day: "Fri", minutes: 55), .init(day: "Sat", minutes: 96),
        .init(day: "Sun", minutes: 72),
    ]

    private let shares: [ShareStat] = Soundscape.all.prefix(5).enumerated().map { i, s in
        ShareStat(id: s.id, scape: s, minutes: [140, 95, 70, 48, 30][i])
    }

    private let palette: [Color] = [
        Color(hex: 0x0D0A24), Color(hex: 0x1A1440), Color(hex: 0x0E0B2A),
        Color(hex: 0x2A2470), Color(hex: 0x3E3A9A), Color(hex: 0x1F2A66),
        Color(hex: 0x0B0A22), Color(hex: 0x24206A), Color(hex: 0x120E33),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Range", selection: $range) {
                        Text("Week").tag(0)
                        Text("Month").tag(1)
                        Text("Year").tag(2)
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        StatTile(value: grown ? 448 : 0, unit: "min", label: "Listened", symbol: "headphones", tint: .teal)
                        StatTile(value: grown ? 12 : 0, unit: "days", label: "Streak", symbol: "flame.fill", tint: .orange)
                        StatTile(value: grown ? 21 : 0, unit: "", label: "Sessions", symbol: "moon.stars.fill", tint: .purple)
                    }

                    weeklyChart
                    favouritesChart
                    consistency
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background {
                MeshBackdrop(palette: palette, speed: 0.4, amplitude: 0.1).ignoresSafeArea()
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share", systemImage: "square.and.arrow.up") {}
                }
            }
            .onAppear {
                withAnimation(.spring(duration: 1.1, bounce: 0.25).delay(0.15)) { grown = true }
            }
            .onDisappear { grown = false }
        }
    }

    private var weeklyChart: some View {
        Card(title: "Listening", subtitle: selectedDay.map { day in
            "\(Int(week.first { $0.day == day }?.minutes ?? 0)) minutes on \(day)"
        } ?? "Average 64 min / night") {
            Chart {
                ForEach(week) { stat in
                BarMark(
                    x: .value("Day", stat.day),
                    y: .value("Minutes", grown ? stat.minutes : 0),
                    width: .ratio(0.55)
                )
                .cornerRadius(8)
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: 0x7FE0D0), Color(hex: 0x6A5BE2)], startPoint: .top, endPoint: .bottom)
                )
                .opacity(selectedDay == nil || selectedDay == stat.day ? 1 : 0.35)
                }

                RuleMark(y: .value("Goal", 60))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.white.opacity(0.4))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal").font(.caption2).foregroundStyle(.white.opacity(0.6))
                    }
            }
            .chartYScale(domain: 0...110)
            .chartYAxis {
                AxisMarks(values: [0, 30, 60, 90]) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.6))
                }
            }
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel().foregroundStyle(.white.opacity(0.7)) }
            }
            .chartXSelection(value: $selectedDay)
            .frame(height: 200)
            .animation(.smooth, value: selectedDay)
        }
    }

    private var favouritesChart: some View {
        Card(title: "Favourite atmospheres", subtitle: "Share of listening time") {
            HStack(spacing: 18) {
                Chart(shares) { s in
                    SectorMark(
                        angle: .value("Minutes", grown ? s.minutes : 0.001),
                        innerRadius: .ratio(0.62),
                        angularInset: 2.5
                    )
                    .cornerRadius(6)
                    .foregroundStyle(s.scape.accent)
                }
                .frame(width: 140, height: 140)
                .overlay {
                    VStack(spacing: 0) {
                        Text("383").font(.title3.bold())
                        Text("min").font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(shares) { s in
                        HStack(spacing: 8) {
                            Circle().fill(s.scape.accent).frame(width: 9, height: 9)
                            Text(s.scape.name).font(.subheadline)
                            Spacer()
                            Text("\(Int(s.minutes))").font(.subheadline.monospacedDigit()).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private var consistency: some View {
        Card(title: "Consistency", subtitle: "Last five weeks") {
            let levels: [Double] = (0..<35).map { i in
                let v = (sin(Double(i) * 1.7) + 1) / 2
                return i % 9 == 4 ? 0 : 0.25 + v * 0.75
            }
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<5, id: \.self) { week in
                    GridRow {
                        ForEach(0..<7, id: \.self) { day in
                            let level = levels[week * 7 + day]
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(hex: 0x7FE0D0).opacity(level == 0 ? 0.08 : level))
                                .aspectRatio(1, contentMode: .fit)
                                .scaleEffect(grown ? 1 : 0.2)
                                .opacity(grown ? 1 : 0)
                                .animation(.spring(duration: 0.6, bounce: 0.4).delay(Double(week * 7 + day) * 0.012), value: grown)
                        }
                    }
                }
            }
        }
    }
}

private struct StatTile: View {
    let value: Double
    let unit: String
    let label: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: value)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value, format: .number.precision(.fractionLength(0)))
                    .font(.title2.bold().monospacedDigit())
                    .contentTransition(.numericText(value: value))
                Text(unit).font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

private struct Card<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .contentTransition(.numericText())
            }
            content
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}
