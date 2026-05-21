import SwiftUI

struct CalendarStatsView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var timerVM: FocusTimerViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(["Calendar", "Stats", "History"].indices, id: \.self) { i in
                            let label = ["Calendar", "Stats", "History"][i]
                            Button {
                                withAnimation(PenguTheme.spring()) { selectedTab = i }
                            } label: {
                                Text(label)
                                    .font(PenguTheme.bodyFont(15))
                                    .foregroundColor(selectedTab == i ? .white : PenguTheme.activeBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedTab == i ?
                                        AnyView(RoundedRectangle(cornerRadius: 12).fill(PenguTheme.iceGradient)) :
                                        AnyView(Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.7)))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Content
                    if selectedTab == 0 {
                        CalendarTabView(selectedDate: $selectedDate, currentMonth: $currentMonth)
                            .environmentObject(routineVM)
                    } else if selectedTab == 1 {
                        StatsTabView()
                            .environmentObject(routineVM)
                            .environmentObject(timerVM)
                            .environmentObject(statsVM)
                    } else {
                        HistoryTabView()
                            .environmentObject(routineVM)
                            .environmentObject(timerVM)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            statsVM.refresh(blocks: routineVM.blocks, sessions: timerVM.sessions)
        }
    }
}

// MARK: - Calendar Tab
struct CalendarTabView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    @EnvironmentObject var routineVM: RoutineViewModel
    @State private var showAddEvent = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Month nav
                HStack {
                    Button {
                        withAnimation(PenguTheme.spring()) {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PenguTheme.activeBlue)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.8)))
                    }
                    Spacer()
                    Text(monthYearLabel)
                        .font(PenguTheme.titleFont(18))
                        .foregroundColor(PenguTheme.darkText)
                    Spacer()
                    Button {
                        withAnimation(PenguTheme.spring()) {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PenguTheme.activeBlue)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.8)))
                    }
                }
                .padding(.horizontal, 16)

                // Day headers
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(PenguTheme.captionFont(12))
                            .foregroundColor(PenguTheme.darkText.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)

                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            CalendarDayCell(
                                date: date,
                                isToday: calendar.isDateInToday(date),
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                completionRate: routineVM.completionForDate(date),
                                hasBlocks: !routineVM.blocksForDate(date).isEmpty
                            ) {
                                withAnimation(PenguTheme.spring()) { selectedDate = date }
                            }
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Selected day blocks
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedDayLabel)
                            .font(PenguTheme.titleFont(17))
                            .foregroundColor(PenguTheme.darkText)
                        Spacer()
                        Button {
                            withAnimation(PenguTheme.spring()) { selectedDate = Date() }
                        } label: {
                            Text("Today")
                                .font(PenguTheme.captionFont(12))
                                .foregroundColor(PenguTheme.activeBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(PenguTheme.iceBlue.opacity(0.12)))
                        }
                    }

                    let dayBlocks = routineVM.blocksForDate(selectedDate)
                    if dayBlocks.isEmpty {
                        Text("No blocks for this day")
                            .font(PenguTheme.captionFont(14))
                            .foregroundColor(PenguTheme.darkText.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(20)
                    } else {
                        ForEach(dayBlocks.sorted { $0.startTime < $1.startTime }) { block in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(block.category.gradient)
                                    .frame(width: 10, height: 10)
                                Text(block.name)
                                    .font(PenguTheme.bodyFont(14))
                                    .foregroundColor(PenguTheme.darkText)
                                    .strikethrough(block.isCompleted)
                                Spacer()
                                Text(block.timeRangeString)
                                    .font(PenguTheme.captionFont(12))
                                    .foregroundColor(PenguTheme.darkText.opacity(0.5))
                                Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(block.isCompleted ? PenguTheme.stateNormal : PenguTheme.iceBlue.opacity(0.3))
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.8)))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .padding(.top, 8)
        }
    }

    var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    var monthYearLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: currentMonth)
    }

    var selectedDayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: selectedDate)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let completionRate: Double
    let hasBlocks: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(PenguTheme.iceGradient)
                } else if isToday {
                    Circle()
                        .stroke(PenguTheme.iceBlue, lineWidth: 2)
                }

                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(PenguTheme.bodyFont(14))
                        .foregroundColor(isSelected ? .white : (isToday ? PenguTheme.activeBlue : PenguTheme.darkText))

                    if hasBlocks {
                        Circle()
                            .fill(completionRate >= 1.0 ? PenguTheme.stateNormal : (completionRate > 0 ? PenguTheme.iceBlue : PenguTheme.darkText.opacity(0.2)))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(height: 44)
        }
    }
}

// MARK: - Stats Tab
struct StatsTabView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var timerVM: FocusTimerViewModel
    @EnvironmentObject var statsVM: StatsViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Period selector
                HStack(spacing: 8) {
                    ForEach(StatsViewModel.StatPeriod.allCases, id: \.self) { period in
                        Button {
                            withAnimation(PenguTheme.spring()) {
                                statsVM.selectedPeriod = period
                                statsVM.refresh(blocks: routineVM.blocks, sessions: timerVM.sessions)
                            }
                        } label: {
                            Text(period.rawValue)
                                .font(PenguTheme.bodyFont(13))
                                .foregroundColor(statsVM.selectedPeriod == period ? .white : PenguTheme.activeBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(statsVM.selectedPeriod == period ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color.white.opacity(0.7))))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // Summary cards
                HStack(spacing: 12) {
                    StatSummaryCard(title: "Focus Hours", value: String(format: "%.1f", statsVM.totalFocusHours(sessions: timerVM.sessions)), icon: "clock.fill", color: PenguTheme.iceBlue)
                    StatSummaryCard(title: "Best Streak", value: "\(statsVM.bestStreak(blocks: routineVM.blocks))d", icon: "snowflake", color: PenguTheme.iceGlow)
                }
                .padding(.horizontal, 16)

                // Weekly bar chart
                VStack(alignment: .leading, spacing: 14) {
                    Text("Weekly Progress")
                        .font(PenguTheme.titleFont(16))
                        .foregroundColor(PenguTheme.darkText)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(statsVM.weeklyData) { day in
                            VStack(spacing: 6) {
                                // Bar
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(PenguTheme.iceBlue.opacity(0.1))
                                        .frame(height: 100)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            day.completionRate >= 1.0 ?
                                            AnyShapeStyle(LinearGradient(colors: [PenguTheme.stateNormal, Color(hex: "16A34A")], startPoint: .top, endPoint: .bottom)) :
                                            AnyShapeStyle(PenguTheme.iceGradient)
                                        )
                                        .frame(height: max(6, CGFloat(day.completionRate) * 100))
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05), value: day.completionRate)
                                }
                                .frame(maxWidth: .infinity)

                                Text(day.label)
                                    .font(PenguTheme.captionFont(11))
                                    .foregroundColor(PenguTheme.darkText.opacity(0.5))
                            }
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
                .iceCard()
                .padding(.horizontal, 16)

                // Category breakdown
                let breakdown = statsVM.categoryBreakdown(blocks: routineVM.blocks)
                if !breakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Activity by Type")
                            .font(PenguTheme.titleFont(16))
                            .foregroundColor(PenguTheme.darkText)

                        let total = breakdown.reduce(0) { $0 + $1.1 }
                        ForEach(breakdown.prefix(5), id: \.0) { cat, count in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(cat.color.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 13))
                                        .foregroundColor(cat.color)
                                }
                                Text(cat.rawValue)
                                    .font(PenguTheme.bodyFont(14))
                                    .foregroundColor(PenguTheme.darkText)
                                Spacer()
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(cat.color.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(cat.gradient)
                                            .frame(width: geo.size.width * (CGFloat(count) / CGFloat(total)))
                                    }
                                    .frame(height: 8)
                                }
                                .frame(width: 80, height: 8)
                                Text("\(count)")
                                    .font(PenguTheme.captionFont(12))
                                    .foregroundColor(cat.color)
                                    .frame(width: 24, alignment: .trailing)
                            }
                        }
                    }
                    .padding()
                    .iceCard()
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 120)
            }
            .padding(.top, 8)
        }
        .onAppear {
            statsVM.refresh(blocks: routineVM.blocks, sessions: timerVM.sessions)
        }
    }
}

struct StatSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(PenguTheme.titleFont(24))
                .foregroundColor(PenguTheme.darkText)
            Text(title)
                .font(PenguTheme.captionFont(12))
                .foregroundColor(PenguTheme.darkText.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .iceCard()
    }
}

// MARK: - History Tab
struct HistoryTabView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var timerVM: FocusTimerViewModel
    @State private var historyFilter: HistoryFilter = .all

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case done = "Completed"
        case missed = "Missed"
    }

    var filteredBlocks: [IceBlock] {
        let sorted = routineVM.blocks.sorted { $0.date > $1.date }
        switch historyFilter {
        case .all: return sorted
        case .done: return sorted.filter { $0.isCompleted }
        case .missed: return sorted.filter { !$0.isCompleted && $0.date < Date() }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Filter
            HStack(spacing: 8) {
                ForEach(HistoryFilter.allCases, id: \.self) { f in
                    Button {
                        withAnimation(PenguTheme.spring()) { historyFilter = f }
                    } label: {
                        Text(f.rawValue)
                            .font(PenguTheme.bodyFont(12))
                            .foregroundColor(historyFilter == f ? .white : PenguTheme.activeBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(historyFilter == f ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color.white.opacity(0.7))))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(filteredBlocks.prefix(50)) { block in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(block.category.color.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: block.category.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(block.category.color)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(block.name)
                                    .font(PenguTheme.bodyFont(14))
                                    .foregroundColor(PenguTheme.darkText)
                                    .strikethrough(block.isCompleted)
                                Text(historyDate(block.date))
                                    .font(PenguTheme.captionFont(12))
                                    .foregroundColor(PenguTheme.darkText.opacity(0.45))
                            }
                            Spacer()
                            Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(block.isCompleted ? PenguTheme.stateNormal : PenguTheme.stateMiss.opacity(0.5))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.8)))
                    }
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    func historyDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f.string(from: date)
    }
}
