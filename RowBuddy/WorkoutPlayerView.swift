import SwiftUI

struct WorkoutPlayerView: View {
    // MARK: - State Variables for Main Timer Display
    @State private var currentIntervalProgress: Double = 1.0 // 1.0 = full, 0.0 = empty
    @State private var countdownValue: Int? = nil // Optional, for 5,4,3,2,1 countdown

    // Placeholder for actual main timer logic (we'll build this later)
    @State private var simulatedRemainingTime: Int = 10 // Simulate 10 seconds remaining for testing countdown
    @State private var totalIntervalDuration: Int = 30 // Simulate a 30 second interval for testing progress

    // MARK: - State Variables for SPM Pacing Circle (Hand removed)
    @State private var targetSPM: Int = 24 // Example target SPM
    @State private var spmCycleProgress: Double = 0.0 // 0.0 = empty, 1.0 = full fill of one cycle

    // Timer to update SPM circle rotation for preview only
    @State private var spmTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            HStack {
                // MARK: - Left Section: Current Interval Details
                VStack(alignment: .leading) {
                    Text("Segment Name: Warm Up")
                        .font(.title2)
                        .padding(.bottom, 5)

                    Text("Remaining: \(simulatedRemainingTime / 60):\(String(format: "%02d", simulatedRemainingTime % 60))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.bottom, 10)

                    Text("Target SPM: \(targetSPM)")
                        .font(.title3)
                        .padding(.bottom, 5)

                    Text("Goal Split: 1:55/500m")
                        .font(.title3)
                }
                .frame(width: geometry.size.width * 0.30)
                .padding(.leading)

                Spacer()

                // MARK: - Central Section: Combined Timers (Bullseye Effect)
                ZStack { // This ZStack now contains both circles, layering them
                    // MARK: - Main time interval circle
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
                            .animation(.linear(duration: 0.1), value: currentIntervalProgress)

                        if let countdown = countdownValue {
                            Text("\(countdown)")
                                .font(.system(size: 80, weight: .black, design: .rounded))
                                .foregroundColor(countdown <= 3 ? .red : .white)
                                .transition(.opacity)
                        } else {
                            Text("")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: geometry.size.height * 0.5, height: geometry.size.height * 0.5) // Sizing for the large circle


                    // MARK: - Dynamic SPM Pacing Circle (Fill from Center)
                    ZStack {
                        // Background (empty) circle - remains an outline
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 15)
                            .background(Circle().fill(Color.yellow.opacity(0.1))) // Inner background color behind the outline

                        if targetSPM > 0 {
                            // The filling segment - now a filled circle that scales
                            Circle()
                                .fill(Color.yellow) // It's a solid circle
                                .scaleEffect(spmCycleProgress) // It scales from 0.0 to 1.0
                                .animation(
                                    .linear(duration: (targetSPM > 0 ? 60.0 / Double(targetSPM) : 1.0)), // Animate over one stroke duration
                                    value: spmCycleProgress
                                )
                                // Removed .rotationEffect as it's not a sweep animation
                        }
                    }
                    .frame(width: geometry.size.height * 0.2, height: geometry.size.height * 0.2) // Sizing for the smaller circle
                }
                .frame(width: geometry.size.width * 0.40) // The combined ZStack now takes the central width

                Spacer()

                // MARK: - Right Section: Overall Time & Controls
                VStack {
                    Text("Total Elapsed:")
                        .font(.title2)
                        .padding(.bottom, 5)

                    Text("00:05:45") // Overall time elapsed placeholder
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.bottom, 30)

                    Button("Start / Pause") {
                        // Simulate main timer progress for preview purposes
                        if simulatedRemainingTime > 0 {
                            simulatedRemainingTime -= 1
                            currentIntervalProgress = Double(simulatedRemainingTime) / Double(totalIntervalDuration)
                            if simulatedRemainingTime <= 5 && simulatedRemainingTime > 0 {
                                countdownValue = simulatedRemainingTime
                            } else if simulatedRemainingTime == 0 {
                                countdownValue = nil
                                simulatedRemainingTime = totalIntervalDuration
                                currentIntervalProgress = 1.0
                            } else {
                                countdownValue = nil
                            }
                        }

                        // Toggle SPM timer for preview
                        if spmTimer == nil {
                            startSPMTimer()
                        } else {
                            stopSPMTimer()
                        }
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.bottom, 10)

                    Button("Reset Workout") {
                        stopSPMTimer()
                        spmCycleProgress = 0.0 // Reset fill
                        simulatedRemainingTime = totalIntervalDuration // Reset main timer
                        currentIntervalProgress = 1.0 // Reset main timer progress
                        countdownValue = nil // Clear countdown
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.bottom, 10)

                    Button("Skip Interval") {
                        // Action for button
                    }
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .frame(width: geometry.size.width * 0.30)
                .padding(.trailing)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .foregroundColor(.white)
        }
        .statusBarHidden(true)
    }

    // MARK: - SPM Timer Logic (For Preview Only)
    func startSPMTimer() {
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
}

// MARK: - Preview Provider
struct WorkoutPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutPlayerView()
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDevice("iPhone 15 Pro Max")
    }
}
