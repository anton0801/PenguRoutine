import SwiftUI

struct RoutineView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    @State private var showAddBlock = false
    @State private var editingBlock: IceBlock? = nil
    @State private var showDetail: IceBlock? = nil
    @State private var filter: BlockFilter = .all

    enum BlockFilter: String, CaseIterable {
        case all = "All"
        case todo = "To Do"
        case done = "Done"
    }

    var filteredBlocks: [IceBlock] {
        switch filter {
        case .all: return routineVM.todayBlocks
        case .todo: return routineVM.todayBlocks.filter { !$0.isCompleted }
        case .done: return routineVM.todayBlocks.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    routineHeader

                    // Filter bar
                    filterBar
                        .padding(.bottom, 12)

                    // Block list
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredBlocks) { block in
                                IceBlockCard(block: block,
                                    onToggle: { routineVM.toggleCompletion(block) },
                                    onEdit: { editingBlock = block },
                                    onDelete: { routineVM.deleteBlock(block) },
                                    onDuplicate: { routineVM.duplicateBlock(block) },
                                    onTap: { showDetail = block }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            }

                            if filteredBlocks.isEmpty {
                                emptyState
                            }

                            Spacer().frame(height: 120)
                        }
                        .padding(.horizontal, 16)
                        .animation(PenguTheme.spring(), value: filteredBlocks.count)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddBlock) {
            AddBlockView(isPresented: $showAddBlock)
                .environmentObject(routineVM)
        }
        .sheet(item: $editingBlock) { block in
            EditBlockView(block: block, isPresented: Binding(
                get: { editingBlock != nil },
                set: { if !$0 { editingBlock = nil } }
            ))
            .environmentObject(routineVM)
        }
        .sheet(item: $showDetail) { block in
            BlockDetailView(block: block)
                .environmentObject(routineVM)
        }
    }

    private var routineHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel)
                    .font(PenguTheme.captionFont(13))
                    .foregroundColor(PenguTheme.activeBlue)
                Text("Ice Blocks")
                    .font(PenguTheme.titleFont(26))
                    .foregroundColor(PenguTheme.darkText)
            }
            Spacer()
            // Completion ring
            ZStack {
                Circle()
                    .stroke(PenguTheme.iceBlue.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: routineVM.completionRate)
                    .stroke(PenguTheme.iceGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(routineVM.completionRate * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(PenguTheme.activeBlue)
            }
            .frame(width: 50, height: 50)
            .animation(PenguTheme.spring(), value: routineVM.completionRate)

            Button {
                withAnimation(PenguTheme.spring()) { showAddBlock = true }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(PenguTheme.iceGradient))
                    .shadow(color: PenguTheme.iceShadow(0.4), radius: 8, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(BlockFilter.allCases, id: \.self) { f in
                Button {
                    withAnimation(PenguTheme.spring()) { filter = f }
                } label: {
                    Text(f.rawValue)
                        .font(PenguTheme.bodyFont(13))
                        .foregroundColor(filter == f ? .white : PenguTheme.activeBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(filter == f ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color.white.opacity(0.7)))
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "snowflake")
                .font(.system(size: 40))
                .foregroundColor(PenguTheme.iceBlue.opacity(0.4))
            Text("No blocks here")
                .font(PenguTheme.bodyFont(16))
                .foregroundColor(PenguTheme.darkText.opacity(0.5))
            if filter == .all {
                Button("Add Ice Block") { showAddBlock = true }
                    .font(PenguTheme.bodyFont(15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(PenguTheme.iceGradient))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }
}

// MARK: - Ice Block Card
struct IceBlockCard: View {
    let block: IceBlock
    var onToggle: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    var onTap: () -> Void

    @State private var showActions = false
    @State private var pressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Category color strip
            RoundedRectangle(cornerRadius: 4)
                .fill(block.category.gradient)
                .frame(width: 5, height: 60)

            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(block.category.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: block.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(block.category.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(block.name)
                    .font(PenguTheme.bodyFont(15))
                    .foregroundColor(PenguTheme.darkText)
                    .strikethrough(block.isCompleted, color: PenguTheme.darkText.opacity(0.4))

                HStack(spacing: 8) {
                    Label(block.timeRangeString, systemImage: "clock")
                        .font(PenguTheme.captionFont(12))
                        .foregroundColor(PenguTheme.darkText.opacity(0.5))
                    Text("\(block.durationMinutes)m")
                        .font(PenguTheme.captionFont(11))
                        .foregroundColor(block.category.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(block.category.color.opacity(0.12)))
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                Button {
                    withAnimation(PenguTheme.spring()) { onToggle() }
                } label: {
                    Image(systemName: block.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundColor(block.isCompleted ? PenguTheme.stateNormal : PenguTheme.iceBlue.opacity(0.3))
                }

                Button {
                    withAnimation(PenguTheme.spring()) { showActions.toggle() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(PenguTheme.darkText.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(block.isCompleted ? Color.white.opacity(0.65) : Color.white.opacity(0.9))
                .shadow(color: PenguTheme.iceShadow(block.isCompleted ? 0.08 : 0.18), radius: 10, x: 0, y: 4)
        )
        .overlay(
            // Inline action menu
            Group {
                if showActions {
                    HStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 2) {
                            ActionChip(icon: "pencil", label: "Edit", color: PenguTheme.iceBlue) {
                                showActions = false; onEdit()
                            }
                            ActionChip(icon: "doc.on.doc", label: "Copy", color: PenguTheme.iceGlow) {
                                showActions = false; onDuplicate()
                            }
                            ActionChip(icon: "trash", label: "Del", color: PenguTheme.stateMiss) {
                                showActions = false; onDelete()
                            }
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: PenguTheme.iceShadow(0.25), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.trailing, 4)
                    .transition(.asymmetric(insertion: .scale(scale: 0.8, anchor: .trailing).combined(with: .opacity), removal: .scale(scale: 0.8, anchor: .trailing).combined(with: .opacity)))
                }
            }
            , alignment: .bottomTrailing
        )
        .onTapGesture {
            if showActions { withAnimation(PenguTheme.spring()) { showActions = false } }
            else { onTap() }
        }
        .scaleEffect(pressed ? 0.97 : 1.0)
    }
}

struct ActionChip: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
            }
            .foregroundColor(color)
            .frame(width: 40, height: 40)
        }
    }
}
