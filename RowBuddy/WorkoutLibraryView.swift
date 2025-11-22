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
    @ObservedObject private var settings = AppSettings.shared
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutBuilder = false
    @State private var selectedWorkout: Workout?
    @State private var workoutToEdit: Workout?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSettings = false
    @State private var editMode: EditMode = .inactive
    
    var onSignOut: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Loading workouts...")
                            .foregroundColor(.gray)
                    }
                } else if workouts.isEmpty {
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
                                    if editMode == .active {
                                        // In edit mode, tap to edit
                                        workoutToEdit = workout
                                    } else {
                                        // Normal mode, tap to start
                                        selectedWorkout = workout
                                    }
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
                    .environment(\.editMode, $editMode)
                }
            }
            .navigationTitle("Row Buddy")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingWorkoutBuilder = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
                
                if !workouts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(editMode == .active ? "Done" : "Edit") {
                            withAnimation {
                                editMode = editMode == .active ? .inactive : .active
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutBuilder) {
                WorkoutBuilderView(onSave: { name, segments in
                    addWorkout(name: name, segments: segments)
                })
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(onSignOut: {
                    signOut()
                    onSignOut()
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                loadWorkouts()
            }
            .refreshable {
                loadWorkouts()
            }
        }
    }
    
    // MARK: - Workout Management Functions
    func loadWorkouts() {
        isLoading = true
        Task {
            do {
                let fetchedWorkouts = try await SupabaseManager.shared.fetchWorkouts()
                await MainActor.run {
                    workouts = fetchedWorkouts
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load workouts: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    func addWorkout(name: String, segments: [WorkoutSegment]) {
        Task {
            do {
                _ = try await SupabaseManager.shared.saveWorkout(name: name, segments: segments)
                // Reload workouts after saving
                loadWorkouts()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save workout: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    func updateWorkout(_ workout: Workout, name: String, segments: [WorkoutSegment]) {
        Task {
            do {
                try await SupabaseManager.shared.updateWorkout(id: workout.id, name: name, segments: segments)
                // Reload workouts after updating
                loadWorkouts()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update workout: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        Task {
            do {
                try await SupabaseManager.shared.deleteWorkout(id: workout.id)
                // Reload workouts after deleting
                loadWorkouts()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete workout: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    func deleteWorkouts(at offsets: IndexSet) {
        let workoutsToDelete = offsets.map { workouts[$0] }
        for workout in workoutsToDelete {
            deleteWorkout(workout)
        }
    }
    
    func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.signOut()
                // This will trigger the app to show the auth screen again
                // You might need to add more navigation logic here
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Workout Card View
struct WorkoutCardView: View {
    let workout: Workout
    var onPlay: (() -> Void)?
    
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
            if let onPlay = onPlay {
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
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
