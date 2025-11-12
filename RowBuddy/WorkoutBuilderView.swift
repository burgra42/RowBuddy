import SwiftUI

struct WorkoutBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var workoutName: String
    @State private var segments: [WorkoutSegment]
    @State private var showingAddSegment = false
    @State private var editingSegment: WorkoutSegment?
    
    var onSave: (String, [WorkoutSegment]) -> Void
    
    init(workoutName: String = "New Workout",
         segments: [WorkoutSegment] = [],
         onSave: @escaping (String, [WorkoutSegment]) -> Void) {
        _workoutName = State(initialValue: workoutName)
        _segments = State(initialValue: segments)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Workout Name
                HStack {
                    Text("Workout Name:")
                        .font(.headline)
                    TextField("e.g., Morning Intervals", text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Segments List
                if segments.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "figure.rowing")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No segments yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first segment")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                            SegmentRowView(segment: segment, index: index + 1)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingSegment = segment
                                }
                        }
                        .onDelete(perform: deleteSegments)
                        .onMove(perform: moveSegments)
                    }
                    
                    // Total Duration
                    HStack {
                        Text("Total Duration:")
                            .font(.headline)
                        Spacer()
                        Text(formatTotalDuration())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                }
            }
            .navigationTitle("Build Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        
                        Button(action: { showingAddSegment = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button(action: saveWorkout) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save & Start Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(workoutName.isEmpty || segments.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(workoutName.isEmpty || segments.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSegment) {
                AddSegmentSheet(onAdd: { newSegment in
                    segments.append(newSegment)
                })
            }
            .sheet(item: $editingSegment) { segment in
                EditSegmentSheet(segment: segment, onSave: { updatedSegment in
                    if let index = segments.firstIndex(where: { $0.id == segment.id }) {
                        segments[index] = updatedSegment
                    }
                })
            }
        }
    }
    
    func deleteSegments(at offsets: IndexSet) {
        segments.remove(atOffsets: offsets)
    }
    
    func moveSegments(from source: IndexSet, to destination: Int) {
        segments.move(fromOffsets: source, toOffset: destination)
    }
    
    func saveWorkout() {
        guard !workoutName.isEmpty && !segments.isEmpty else { return }
        onSave(workoutName, segments)
        dismiss()
    }
    
    func formatTotalDuration() -> String {
        let totalSeconds = segments.reduce(0) { $0 + $1.durationSeconds }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Segment Row View
struct SegmentRowView: View {
    let segment: WorkoutSegment
    let index: Int
    
    var body: some View {
        HStack {
            // Index circle
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label(formatDuration(segment.durationSeconds), systemImage: "clock")
                    Label("\(segment.targetSPM) SPM", systemImage: "figure.rowing")
                    Label(segment.goalSplit, systemImage: "gauge")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Add Segment Sheet
struct AddSegmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var segmentName: String = ""
    @State private var durationMinutes: Int = 5
    @State private var durationSeconds: Int = 0
    @State private var targetSPM: Int = 24
    @State private var goalSplit: String = "2:00/500m"
    
    @State private var isInterval = false
    @State private var intervalCount = 3
    @State private var restDurationMinutes = 1
    @State private var restDurationSeconds = 0
    @State private var restSPM = 18
    
    let onAdd: (WorkoutSegment) -> Void
    
    private var totalWorkDuration: Int {
        (durationMinutes * 60) + durationSeconds
    }
    
    private var totalRestDuration: Int {
        (restDurationMinutes * 60) + restDurationSeconds
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Toggle for interval mode
                Section {
                    Toggle("Create as Interval Set", isOn: $isInterval)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                if isInterval {
                    // Interval configuration
                    Section(header: Text("Interval Configuration")) {
                        HStack {
                            Text("Number of Intervals:")
                            Spacer()
                            Picker("Count", selection: $intervalCount) {
                                ForEach(2...20, id: \.self) { count in
                                    Text("\(count)").tag(count)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Rest Between Intervals:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Picker("Minutes", selection: $restDurationMinutes) {
                                    ForEach(0...10, id: \.self) { minute in
                                        Text("\(minute)").tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                Text("min")
                                
                                Picker("Seconds", selection: $restDurationSeconds) {
                                    ForEach(0...59, id: \.self) { second in
                                        Text("\(second)").tag(second)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                Text("sec")
                            }
                        }
                        
                        HStack {
                            Text("Rest SPM:")
                            Spacer()
                            Picker("Rest SPM", selection: $restSPM) {
                                ForEach(10...30, id: \.self) { spm in
                                    Text("\(spm)").tag(spm)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    Section(header: Text("Work Interval Details")) {
                        TextField("Period Name (e.g., Interval)", text: $segmentName)
                        
                        VStack(alignment: .leading) {
                            Text("Duration:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Picker("Minutes", selection: $durationMinutes) {
                                    ForEach(0...60, id: \.self) { minute in
                                        Text("\(minute)").tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                Text("min")
                                
                                Picker("Seconds", selection: $durationSeconds) {
                                    ForEach(0...59, id: \.self) { second in
                                        Text("\(second)").tag(second)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                Text("sec")
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Target SPM:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Target SPM", selection: $targetSPM) {
                                ForEach(10...40, id: \.self) { spm in
                                    Text("\(spm) SPM").tag(spm)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                        }
                        
                        TextField("Goal Split (e.g., 1:55/500m)", text: $goalSplit)
                    }
                } else {
                    // Single segment
                    Section(header: Text("Segment Details")) {
                        TextField("Period Name (e.g., Warm Up)", text: $segmentName)
                        
                        VStack(alignment: .leading) {
                            Text("Duration:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Picker("Minutes", selection: $durationMinutes) {
                                    ForEach(0...60, id: \.self) { minute in
                                        Text("\(minute)").tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                Text("min")
                                
                                Picker("Seconds", selection: $durationSeconds) {
                                    ForEach(0...59, id: \.self) { second in
                                        Text("\(second)").tag(second)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60)
                                .clipped()
                                Text("sec")
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Target SPM:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Target SPM", selection: $targetSPM) {
                                ForEach(10...40, id: \.self) { spm in
                                    Text("\(spm) SPM").tag(spm)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                        }
                        
                        TextField("Goal Split (e.g., 1:55/500m)", text: $goalSplit)
                    }
                }
            }
            .navigationTitle(isInterval ? "Add Interval Set" : "Add Segment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSegments()
                        dismiss()
                    }
                    .disabled(segmentName.isEmpty)
                }
            }
        }
    }
    
    func addSegments() {
        if isInterval {
            // Create alternating work/rest segments
            for i in 1...intervalCount {
                // Work segment
                let workSegment = WorkoutSegment(
                    name: segmentName,
                    durationSeconds: totalWorkDuration,
                    targetSPM: targetSPM,
                    goalSplit: goalSplit,
                    periodNumber: "\(i) of \(intervalCount)"
                )
                onAdd(workSegment)
                
                // Rest segment (except after last interval)
                if i < intervalCount {
                    let restSegment = WorkoutSegment(
                        name: "Rest",
                        durationSeconds: totalRestDuration,
                        targetSPM: restSPM,
                        goalSplit: "2:20/500m",
                        periodNumber: "\(i) of \(intervalCount)"
                    )
                    onAdd(restSegment)
                }
            }
        } else {
            // Single segment
            let segment = WorkoutSegment(
                name: segmentName,
                durationSeconds: totalWorkDuration,
                targetSPM: targetSPM,
                goalSplit: goalSplit,
                periodNumber: ""
            )
            onAdd(segment)
        }
    }
}

// MARK: - Edit Segment Sheet
struct EditSegmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var editedSegment: WorkoutSegment
    
    let onSave: (WorkoutSegment) -> Void
    
    init(segment: WorkoutSegment, onSave: @escaping (WorkoutSegment) -> Void) {
        _editedSegment = State(initialValue: segment)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            WorkoutSegmentConfigView(segment: $editedSegment, isNewSegment: false)
                .navigationTitle("Edit Segment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            onSave(editedSegment)
                            dismiss()
                        }
                        .disabled(editedSegment.name.isEmpty)
                    }
                }
        }
    }
}

// MARK: - Preview
struct WorkoutBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutBuilderView(
            workoutName: "Test Workout",
            segments: [
                WorkoutSegment(name: "Warm Up", durationSeconds: 300, targetSPM: 20, goalSplit: "2:00/500m"),
                WorkoutSegment(name: "Interval", durationSeconds: 120, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "1 of 5")
            ],
            onSave: { name, segments in
                print("Saved: \(name) with \(segments.count) segments")
            }
        )
    }
}
