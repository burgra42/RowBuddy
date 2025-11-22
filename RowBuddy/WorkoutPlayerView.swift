import SwiftUI

struct WorkoutPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // MARK: - Workout Data
    let segments: [WorkoutSegment]
    
    // MARK: - State Variables for Workout Progress
    @State private var currentSegmentIndex: Int = 0
    @State private var remainingTimeInSegment: Int = 0
    @State private var totalElapsedTime: Int = 0
    @State private var isRunning: Bool = false
    @State private var workoutTimer: Timer?
    @State private var showingExitConfirmation = false
    
    // MARK: - State Variables for Display
    @State private var currentIntervalProgress: Double = 1.0
    @State private var countdownValue: Int? = nil
    
    // MARK: - State Variables for SPM Pacing Circle
    @State private var spmCycleProgress: Double = 0.0
    @State private var spmTimer: Timer?
    
    // MARK: - Computed Properties
    private var currentSegment: WorkoutSegment? {
        guard currentSegmentIndex < segments.count else { return nil }
        return segments[currentSegmentIndex]
    }
    
    private var isWorkoutComplete: Bool {
        currentSegmentIndex >= segments.count
    }
    
    private var isPortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
    
    // MARK: - Initializer
    init(segments: [WorkoutSegment]) {
        self.segments = segments
        _remainingTimeInSegment = State(initialValue: segments.first?.durationSeconds ?? 0)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if isPortrait {
                portraitLayout
            } else {
                landscapeLayout
            }
            
            // MARK: - Exit button overlay (both orientations)
            Button(action: {
                if isRunning {
                    showingExitConfirmation = true
                } else {
                    dismiss()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                    Text("Exit")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            }
            .padding([.top, .leading], 20)
        }
        .statusBarHidden(false)
        .confirmationDialog(
            "Exit Workout?",
            isPresented: $showingExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Exit Workout", role: .destructive) {
                pauseWorkout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your workout progress will be lost.")
        }
    }
    
    // MARK: - Portrait Layout
    var portraitLayout: some View {
        VStack(spacing: 0) {
            // Top: Segment info
            VStack(spacing: 12) {
                if let segment = currentSegment {
                    Text(segment.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !segment.periodNumber.isEmpty {
                        Text(segment.periodNumber)
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("TARGET SPM")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(segment.targetSPM)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        
                        VStack {
                            Text("GOAL SPLIT")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(segment.goalSplit)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 8)
                } else if isWorkoutComplete {
                    Text("Workout Complete!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            Spacer()
            
            // Middle: Timer circles
            ZStack {
                // Main interval circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 40)
                    
                    Circle()
                        .trim(from: 0.0, to: currentIntervalProgress)
                        .stroke(
                            currentIntervalProgress > 0.1 ? Color.blue : Color.red,
                            style: StrokeStyle(lineWidth: 35, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: currentIntervalProgress)
                    
                    // Time display
                    VStack(spacing: 4) {
                        if let countdown = countdownValue {
                            Text("\(countdown)")
                                .font(.system(size: 100, weight: .black, design: .rounded))
                                .foregroundColor(countdown <= 3 ? .red : .white)
                        } else if isWorkoutComplete {
                            Text("✓")
                                .font(.system(size: 80, weight: .black))
                                .foregroundColor(.green)
                        } else {
                            Text(formatTime(remainingTimeInSegment))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("REMAINING")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: 300, height: 300)
                
                // SPM circle
                spmCircle(size: 80)
                    .offset(x: 110, y: 110)
            }
            .padding(.vertical, 40)
            
            Spacer()
            
            // Bottom: Controls
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("TOTAL ELAPSED")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(formatTime(totalElapsedTime))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.purple)
                }
                .padding(.bottom, 10)
                
                HStack(spacing: 15) {
                    controlButton(icon: "arrow.counterclockwise", label: "Reset", color: .red, action: resetWorkout)
                    controlButton(icon: isRunning ? "pause.fill" : "play.fill", label: isRunning ? "Pause" : "Start", color: isRunning ? .orange : .green, action: togglePlayPause, disabled: isWorkoutComplete, isLarge: true)
                    controlButton(icon: "forward.fill", label: "Skip", color: .gray, action: skipToNextSegment, disabled: isWorkoutComplete)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - Landscape Layout
    var landscapeLayout: some View {
        GeometryReader { geometry in
            HStack {
                // Left: Segment details
                VStack(alignment: .leading) {
                    if let segment = currentSegment {
                        Text("Segment: \(segment.name)")
                            .font(.title2)
                            .padding(.bottom, 5)
                        
                        if !segment.periodNumber.isEmpty {
                            Text("Period: \(segment.periodNumber)")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(.bottom, 5)
                        }
                        
                        Text("Remaining: \(formatTime(remainingTimeInSegment))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.bottom, 10)
                        
                        Text("Target SPM: \(segment.targetSPM)")
                            .font(.title3)
                            .padding(.bottom, 5)
                        
                        Text("Goal Split: \(segment.goalSplit)")
                            .font(.title3)
                    } else if isWorkoutComplete {
                        Text("Workout Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .frame(width: geometry.size.width * 0.30)
                .padding(.leading)
                
                Spacer()
                
                // Center: Timer circles
                ZStack {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 100)
                        
                        Circle()
                            .trim(from: 0.0, to: currentIntervalProgress)
                            .stroke(
                                currentIntervalProgress > 0.1 ? Color.blue : Color.red,
                                style: StrokeStyle(lineWidth: 70, lineCap: .butt)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1.0), value: currentIntervalProgress)
                        
                        if let countdown = countdownValue {
                            Text("\(countdown)")
                                .font(.system(size: 80, weight: .black, design: .rounded))
                                .foregroundColor(countdown <= 3 ? .red : .white)
                                .transition(.opacity)
                        } else if isWorkoutComplete {
                            Text("✓")
                                .font(.system(size: 80, weight: .black))
                                .foregroundColor(.green)
                        }
                    }
                    .frame(width: geometry.size.height * 0.5, height: geometry.size.height * 0.5)
                    
                    spmCircle(size: geometry.size.height * 0.2)
                }
                .frame(width: geometry.size.width * 0.40)
                
                Spacer()
                
                // Right: Controls
                VStack {
                    Text("Total Elapsed:")
                        .font(.title2)
                        .padding(.bottom, 5)
                    
                    Text(formatTime(totalElapsedTime))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.bottom, 30)
                    
                    Button(isRunning ? "Pause" : "Start") {
                        togglePlayPause()
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRunning ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.bottom, 10)
                    .disabled(isWorkoutComplete)
                    
                    Button("Reset Workout") {
                        resetWorkout()
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.bottom, 10)
                    
                    Button("Skip Interval") {
                        skipToNextSegment()
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .disabled(isWorkoutComplete)
                }
                .frame(width: geometry.size.width * 0.30)
                .padding(.trailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Reusable Components
    func spmCircle(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: size * 0.1)
                .background(Circle().fill(Color.yellow.opacity(0.1)))
            
            if let segment = currentSegment, segment.targetSPM > 0 {
                Circle()
                    .fill(Color.yellow)
                    .scaleEffect(spmCycleProgress)
                    .animation(
                        .linear(duration: 60.0 / Double(segment.targetSPM)),
                        value: spmCycleProgress
                    )
            }
            
            Text("SPM")
                .font(.system(size: size * 0.15))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
    
    func controlButton(icon: String, label: String, color: Color, action: @escaping () -> Void, disabled: Bool = false, isLarge: Bool = false) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 40 : 28))
                Text(label)
                    .font(isLarge ? .headline : .caption)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.opacity(disabled ? 0.3 : 0.8))
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .disabled(disabled)
    }
    
    // MARK: - Timer Control Functions
    func togglePlayPause() {
        if isRunning {
            pauseWorkout()
        } else {
            startWorkout()
        }
    }
    
    func startWorkout() {
        isRunning = true
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            tick()
        }
        
        if let segment = currentSegment, segment.targetSPM > 0 {
            startSPMTimer(targetSPM: segment.targetSPM)
        }
    }
    
    func pauseWorkout() {
        isRunning = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        stopSPMTimer()
    }
    
    func resetWorkout() {
        pauseWorkout()
        currentSegmentIndex = 0
        remainingTimeInSegment = segments.first?.durationSeconds ?? 0
        totalElapsedTime = 0
        currentIntervalProgress = 1.0
        countdownValue = nil
        spmCycleProgress = 0.0
    }
    
    func skipToNextSegment() {
        advanceToNextSegment()
    }
    
    // MARK: - Main Timer Logic
    func tick() {
        if remainingTimeInSegment > 0 {
            remainingTimeInSegment -= 1
            totalElapsedTime += 1
            
            if let segment = currentSegment {
                currentIntervalProgress = Double(remainingTimeInSegment) / Double(segment.durationSeconds)
            }
            
            if remainingTimeInSegment <= 5 && remainingTimeInSegment > 0 {
                countdownValue = remainingTimeInSegment
            } else {
                countdownValue = nil
            }
            
        } else {
            advanceToNextSegment()
        }
    }
    
    func advanceToNextSegment() {
        currentSegmentIndex += 1
        
        if currentSegmentIndex < segments.count {
            let nextSegment = segments[currentSegmentIndex]
            remainingTimeInSegment = nextSegment.durationSeconds
            currentIntervalProgress = 1.0
            countdownValue = nil
            
            if isRunning {
                stopSPMTimer()
                if nextSegment.targetSPM > 0 {
                    startSPMTimer(targetSPM: nextSegment.targetSPM)
                }
            }
        } else {
            pauseWorkout()
            currentIntervalProgress = 0.0
        }
    }
    
    // MARK: - SPM Timer Logic
    func startSPMTimer(targetSPM: Int) {
        guard targetSPM > 0 else {
            stopSPMTimer()
            return
        }
        
        let secondsPerStroke = 60.0 / Double(targetSPM)
        var currentCycleTime: Double = 0.0
        
        stopSPMTimer()
        
        spmTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            currentCycleTime += 0.01
            spmCycleProgress = currentCycleTime / secondsPerStroke
            
            if currentCycleTime >= secondsPerStroke {
                currentCycleTime = 0.0
                spmCycleProgress = 0.0
            }
        }
    }
    
    func stopSPMTimer() {
        spmTimer?.invalidate()
        spmTimer = nil
        spmCycleProgress = 0.0
    }
    
    // MARK: - Helper Functions
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview Provider
struct WorkoutPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleWorkout = [
            WorkoutSegment(name: "Warm Up", durationSeconds: 15, targetSPM: 20, goalSplit: "2:00/500m", periodNumber: ""),
            WorkoutSegment(name: "Interval", durationSeconds: 10, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "1 of 3"),
            WorkoutSegment(name: "Rest", durationSeconds: 8, targetSPM: 18, goalSplit: "2:15/500m", periodNumber: "1 of 3"),
            WorkoutSegment(name: "Interval", durationSeconds: 10, targetSPM: 28, goalSplit: "1:45/500m", periodNumber: "2 of 3"),
            WorkoutSegment(name: "Cool Down", durationSeconds: 12, targetSPM: 18, goalSplit: "2:10/500m", periodNumber: "")
        ]
        
        WorkoutPlayerView(segments: sampleWorkout)
            .previewDevice("iPhone 15 Pro Max")
    }
}
