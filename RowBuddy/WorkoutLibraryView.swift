import SwiftUI

// MARK: - Workout Model
struct Workout: Identifiable, Codable {
    let id: UUID
    var name: String
    var segments: [WorkoutSegment]
    var createdDate: Date
    
    init(id: UUID = UUID(), name: String, segments: [WorkoutSegment], createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.segments = segments
        self.createdDate = createdDate
    }
    
    var totalDuration: Int {
        segments.reduce(0) { $0 + $1.durationSeconds }
    }
    
    var segmentCount: Int {
        segments.count
    }
}

// MARK: - Workout Library View
struct WorkoutLibraryView: View {
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutBuilder = false
    @State private var selectedWorkout: Workout?
    @State private var workoutToEdit: Workout?
    
    var body: some View {
        NavigationView {
            ZStack {
                if workouts.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "figure.rowing")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("No Workouts Yet")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Create your first rowing workout to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingWorkoutBuilder = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Workout")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: 250)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                } else {
                    // Workout List
                    List {
                        ForEach(workouts) { workout in
                            WorkoutCardView(workout: workout)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedWorkout = workout
                                }
                                .contextMenu {
                                    Button(action: { workoutToEdit = workout }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(action: { selectedWorkout = workout }) {
                                        Label("Start Workout", systemImage: "play.fill")
                                    }
                                    
                                    Button(role: .destructive, action: { deleteWorkout(workout) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: deleteWorkouts)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Row Buddy")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingWorkoutBuilder = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
                
                if !workouts.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutBuilder) {
                WorkoutBuilderView(onSave: { name, segments in
                    addWorkout(name: name, segments: segments)
                })
            }
            .sheet(item: $workoutToEdit) { workout in
                WorkoutBuilderView(
                    workoutName: workout.name,
                    segments: workout.segments,
                    onSave: { name, segments in
                        updateWorkout(workout, name: name, segments: segments)
                    }
                )
            }
            .fullScreenCover(item: $selectedWorkout) { workout in
                WorkoutPlayerView(segments: workout.segments)
                    .onDisappear {
                        selectedWorkout = nil
                    }
            }
            .onAppear {
                loadSampleWorkouts()
            }
        }
    }
    
    // MARK: - Workout Management Functions
    func addWorkout(name: String, segments: [WorkoutSegment]) {
        let newWorkout = Workout(name: name, segments: segments)
        workouts.append(newWorkout)
        // TODO: Save to persistent storage
    }
    
    func updateWorkout(_ workout: Workout, name: String, segments: [WorkoutSegment]) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index].name = name
            workouts[index].segments = segments
            // TODO: Save to persistent storage
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        // TODO: Save to persistent storage
    }
    
    func deleteWorkouts(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
        // TODO: Save to persistent storage
    }
    
    // Load some sample workouts for testing
    func loadSampleWorkouts() {
        if workouts.isEmpty {
            // Add a couple sample workouts
            let quickWorkout = Workout(
                name: "Quick 10 Min",
                segments: [
                    WorkoutSegment(name: "Warm Up", durationSeconds: 120, targetSPM: 20, goalSplit: "2:10/500m"),
                    WorkoutSegment(name: "Steady State", durationSeconds: 480, targetSPM: 24, goalSplit: "2:00/500m"),
                    WorkoutSegment(name: "Cool Down", durationSeconds: 120, targetSPM: 18, goalSplit: "2:15/500m")
                ]
            )
            
            let intervalWorkout = Workout(
                name: "5x2min Intervals",
                segments: [
                    WorkoutSegment(name: "Warm Up", durationSeconds: 180, targetSPM: 20, goalSplit: "2:10/500m"),
                    WorkoutSegment(name: "Interval", durationSeconds: 120, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "1 of 5"),
                    WorkoutSegment(name: "Rest", durationSeconds: 60, targetSPM: 18, goalSplit: "2:20/500m", periodNumber: "1 of 5"),
                    WorkoutSegment(name: "Interval", durationSeconds: 120, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "2 of 5"),
                    WorkoutSegment(name: "Rest", durationSeconds: 60, targetSPM: 18, goalSplit: "2:20/500m", periodNumber: "2 of 5"),
                    WorkoutSegment(name: "Interval", durationSeconds: 120, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "3 of 5"),
                    WorkoutSegment(name: "Rest", durationSeconds: 60, targetSPM: 18, goalSplit: "2:20/500m", periodNumber: "3 of 5"),
                    WorkoutSegment(name: "Interval", durationSeconds: 120, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "4 of 5"),
                    WorkoutSegment(name: "Rest", durationSeconds: 60, targetSPM: 18, goalSplit: "2:20/500m", periodNumber: "4 of 5"),
                    WorkoutSegment(name: "Interval", durationSeconds: 120, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "5 of 5"),
                    WorkoutSegment(name: "Cool Down", durationSeconds: 180, targetSPM: 18, goalSplit: "2:15/500m")
                ]
            )
            
            workouts = [quickWorkout, intervalWorkout]
        }
    }
}

// MARK: - Workout Card View
struct WorkoutCardView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "figure.rowing")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(workout.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(workout.segmentCount) segments", systemImage: "list.bullet")
                    Label(formatDuration(workout.totalDuration), systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text(workout.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Play button
            Button(action: {}) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins)min"
        }
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview
struct WorkoutLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLibraryView()
    }
}
