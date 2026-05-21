import SwiftUI

// MARK: - Add Block View
struct AddBlockView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var routineVM: RoutineViewModel

    @State private var name: String = ""
    @State private var category: BlockCategory = .work
    @State private var startTime: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var nameError: Bool = false
    @State private var saved = false

    let durations = [10, 15, 20, 25, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Block Name", systemImage: "textformat")
                                .font(PenguTheme.bodyFont(14))
                                .foregroundColor(PenguTheme.darkText.opacity(0.6))
                            TextField("e.g. Deep Work, Morning Run...", text: $name)
                                .font(PenguTheme.bodyFont(16))
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(nameError ? PenguTheme.stateMiss : PenguTheme.iceBlue.opacity(0.2), lineWidth: 1.5)
                                        )
                                )
                            if nameError {
                                Text("Please enter a name")
                                    .font(PenguTheme.captionFont(12))
                                    .foregroundColor(PenguTheme.stateMiss)
                            }
                        }

                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Category", systemImage: "square.grid.2x2")
                                .font(PenguTheme.bodyFont(14))
                                .foregroundColor(PenguTheme.darkText.opacity(0.6))
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                                ForEach(BlockCategory.allCases, id: \.self) { cat in
                                    CategoryChip(cat: cat, isSelected: category == cat) {
                                        withAnimation(PenguTheme.spring()) { category = cat }
                                    }
                                }
                            }
                        }

                        // Date & Time
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Date & Start Time", systemImage: "calendar.clock")
                                .font(PenguTheme.bodyFont(14))
                                .foregroundColor(PenguTheme.darkText.opacity(0.6))
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                                .onChange(of: startTime) { newVal in date = newVal }
                        }

                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Duration: \(durationMinutes) minutes", systemImage: "timer")
                                .font(PenguTheme.bodyFont(14))
                                .foregroundColor(PenguTheme.darkText.opacity(0.6))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(durations, id: \.self) { d in
                                        Button {
                                            withAnimation(PenguTheme.spring()) { durationMinutes = d }
                                        } label: {
                                            Text("\(d)m")
                                                .font(PenguTheme.bodyFont(13))
                                                .foregroundColor(durationMinutes == d ? .white : PenguTheme.activeBlue)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule().fill(durationMinutes == d ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color.white.opacity(0.8)))
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes (optional)", systemImage: "note.text")
                                .font(PenguTheme.bodyFont(14))
                                .foregroundColor(PenguTheme.darkText.opacity(0.6))
                            TextEditor(text: $notes)
                                .font(PenguTheme.bodyFont(15))
                                .frame(height: 80)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        }

                        // Save button
                        Button {
                            saveBlock()
                        } label: {
                            HStack(spacing: 8) {
                                if saved {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Saved!")
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Ice Block")
                                }
                            }
                            .font(PenguTheme.titleFont(17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(saved ? AnyShapeStyle(LinearGradient(colors: [PenguTheme.stateNormal, Color(hex: "16A34A")], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(PenguTheme.iceGradient))
                            )
                            .shadow(color: PenguTheme.iceShadow(0.4), radius: 12, x: 0, y: 6)
                        }
                        .animation(PenguTheme.spring(), value: saved)

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("New Ice Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(PenguTheme.activeBlue)
                }
            }
        }
    }

    private func saveBlock() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(PenguTheme.spring()) { nameError = true }
            return
        }
        nameError = false
        let block = IceBlock(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            startTime: startTime,
            durationMinutes: durationMinutes,
            notes: notes,
            date: startTime
        )
        routineVM.addBlock(block)
        withAnimation(PenguTheme.spring()) { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isPresented = false
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let cat: BlockCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: cat.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : cat.color)
                Text(cat.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : PenguTheme.darkText.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AnyShapeStyle(cat.gradient) : AnyShapeStyle(Color.white.opacity(0.8)))
                    .shadow(color: isSelected ? cat.color.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Edit Block View
struct EditBlockView: View {
    let block: IceBlock
    @Binding var isPresented: Bool
    @EnvironmentObject var routineVM: RoutineViewModel

    @State private var name: String
    @State private var category: BlockCategory
    @State private var startTime: Date
    @State private var durationMinutes: Int
    @State private var notes: String
    @State private var saved = false

    let durations = [10, 15, 20, 25, 30, 45, 60, 90, 120]

    init(block: IceBlock, isPresented: Binding<Bool>) {
        self.block = block
        self._isPresented = isPresented
        _name = State(initialValue: block.name)
        _category = State(initialValue: block.category)
        _startTime = State(initialValue: block.startTime)
        _durationMinutes = State(initialValue: block.durationMinutes)
        _notes = State(initialValue: block.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        TextField("Block name", text: $name)
                            .font(PenguTheme.bodyFont(16))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(BlockCategory.allCases, id: \.self) { cat in
                                CategoryChip(cat: cat, isSelected: category == cat) {
                                    withAnimation(PenguTheme.spring()) { category = cat }
                                }
                            }
                        }

                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(durations, id: \.self) { d in
                                    Button {
                                        withAnimation(PenguTheme.spring()) { durationMinutes = d }
                                    } label: {
                                        Text("\(d)m")
                                            .font(PenguTheme.bodyFont(13))
                                            .foregroundColor(durationMinutes == d ? .white : PenguTheme.activeBlue)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Capsule().fill(durationMinutes == d ? AnyShapeStyle(PenguTheme.iceGradient) : AnyShapeStyle(Color.white.opacity(0.8))))
                                    }
                                }
                            }
                        }

                        TextEditor(text: $notes)
                            .font(PenguTheme.bodyFont(15))
                            .frame(height: 80)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))

                        Button {
                            var updated = block
                            updated.name = name
                            updated.category = category
                            updated.startTime = startTime
                            updated.durationMinutes = durationMinutes
                            updated.notes = notes
                            updated.date = startTime
                            routineVM.updateBlock(updated)
                            withAnimation(PenguTheme.spring()) { saved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                isPresented = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: saved ? "checkmark.circle.fill" : "pencil.circle.fill")
                                Text(saved ? "Saved!" : "Save Changes")
                            }
                            .font(PenguTheme.titleFont(17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 28).fill(PenguTheme.iceGradient))
                        }
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(PenguTheme.activeBlue)
                }
            }
        }
    }
}

// MARK: - Block Detail View
struct BlockDetailView: View {
    let block: IceBlock
    @EnvironmentObject var routineVM: RoutineViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                PenguTheme.skyGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Hero card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(block.category.gradient)
                                    .frame(width: 80, height: 80)
                                Image(systemName: block.category.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            Text(block.name)
                                .font(PenguTheme.titleFont(22))
                                .foregroundColor(PenguTheme.darkText)
                            HStack(spacing: 12) {
                                StatusBadge(label: block.category.rawValue, color: block.category.color)
                                StatusBadge(label: block.isCompleted ? "Done ✓" : "Pending", color: block.isCompleted ? PenguTheme.stateNormal : PenguTheme.stateCold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .iceCard()

                        // Details
                        VStack(spacing: 14) {
                            DetailRow(icon: "clock.fill", label: "Time", value: block.timeRangeString, color: PenguTheme.iceBlue)
                            DetailRow(icon: "timer", label: "Duration", value: "\(block.durationMinutes) minutes", color: PenguTheme.iceGlow)
                            DetailRow(icon: "calendar", label: "Date", value: formattedDate, color: Color(hex: "818CF8"))
                            if !block.notes.isEmpty {
                                DetailRow(icon: "note.text", label: "Notes", value: block.notes, color: PenguTheme.stateHappy)
                            }
                        }
                        .iceCard()

                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                withAnimation(PenguTheme.spring()) {
                                    routineVM.toggleCompletion(block)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            } label: {
                                Label(block.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: block.isCompleted ? "xmark.circle" : "checkmark.circle.fill")
                                    .font(PenguTheme.bodyFont(16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(RoundedRectangle(cornerRadius: 25).fill(block.isCompleted ? PenguTheme.stateCold : PenguTheme.stateNormal))
                            }

                            HStack(spacing: 12) {
                                Button {
                                    showEdit = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .font(PenguTheme.bodyFont(15))
                                        .foregroundColor(PenguTheme.activeBlue)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                                }

                                Button {
                                    routineVM.duplicateBlock(block)
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                        .font(PenguTheme.bodyFont(15))
                                        .foregroundColor(PenguTheme.iceGlow)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                                }
                            }

                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete Block", systemImage: "trash")
                                    .font(PenguTheme.bodyFont(15))
                                    .foregroundColor(PenguTheme.stateMiss)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(RoundedRectangle(cornerRadius: 24).fill(PenguTheme.stateMiss.opacity(0.1)))
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Block Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(PenguTheme.activeBlue)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditBlockView(block: block, isPresented: $showEdit)
                .environmentObject(routineVM)
        }
        .alert("Delete Block", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                routineVM.deleteBlock(block)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(block.name)\"?")
        }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: block.date)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .font(PenguTheme.captionFont(13))
                .foregroundColor(PenguTheme.darkText.opacity(0.5))
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(PenguTheme.bodyFont(14))
                .foregroundColor(PenguTheme.darkText)
                .lineLimit(3)
            Spacer()
        }
    }
}

struct StatusBadge: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(PenguTheme.captionFont(12))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
