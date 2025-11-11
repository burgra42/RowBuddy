//
//  WorkoutSegmentConfigView.swift
//  RowBuddy
//
//  Created by Will Olson on 7/15/25.
//
// WorkoutSegmentConfigView.swift
import SwiftUI

struct WorkoutSegmentConfigView: View {
    // We'll pass a binding to a segment, so changes here update the parent list
    @Binding var segment: WorkoutSegment
    var isNewSegment: Bool = false // To indicate if it's a new segment being added

    var body: some View {
        Form { // Using Form for organized input fields
            Section(header: Text("Segment Details").font(.headline)) {
                TextField("Period Name (e.g., Warm Up)", text: $segment.name)

                HStack {
                    Text("Duration:")
                    Spacer()
                    // Using a Stepper for easy second increment/decrement
                    Stepper(value: $segment.durationSeconds, in: 10...3600, step: 10) {
                        Text("\(segment.durationSeconds / 60):\(String(format: "%02d", segment.durationSeconds % 60)) min")
                    }
                }

                HStack {
                    Text("Target SPM:")
                    Spacer()
                    Stepper(value: $segment.targetSPM, in: 10...40) {
                        Text("\(segment.targetSPM) SPM")
                    }
                }

                TextField("Goal Split (e.g., 1:55/500m)", text: $segment.goalSplit)

                TextField("Period Number (e.g., 2 of 5)", text: $segment.periodNumber)
            }
        }
        .navigationTitle(isNewSegment ? "New Segment" : segment.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkoutSegmentConfigView_Previews: PreviewProvider {
    // For previewing, we need a State variable to bind to
    @State static var previewSegment = WorkoutSegment.defaultSegment

    static var previews: some View {
        NavigationView { // Embed in NavigationView for title display
            WorkoutSegmentConfigView(segment: $previewSegment)
        }
    }
}
