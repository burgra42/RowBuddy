import SwiftUI

struct WorkoutSegmentConfigView: View {
    @Binding var segment: WorkoutSegment
    var isNewSegment: Bool = false
    
    // Break duration into minutes and seconds for picker
    private var durationMinutes: Int {
        segment.durationSeconds / 60
    }
    
    private var durationSeconds: Int {
        segment.durationSeconds % 60
    }
    
    var body: some View {
        Form {
            Section(header: Text("Segment Details").font(.headline)) {
                TextField("Period Name (e.g., Warm Up)", text: $segment.name)
                
                // Duration Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        // Minutes picker
                        Picker("Minutes", selection: Binding(
                            get: { durationMinutes },
                            set: { newMinutes in
                                segment.durationSeconds = (newMinutes * 60) + durationSeconds
                            }
                        )) {
                            ForEach(0..<61) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                        
                        Text("min")
                            .font(.headline)
                        
                        // Seconds picker
                        Picker("Seconds", selection: Binding(
                            get: { durationSeconds },
                            set: { newSeconds in
                                segment.durationSeconds = (durationMinutes * 60) + newSeconds
                            }
                        )) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                        
                        Text("sec")
                            .font(.headline)
                    }
                }
                
                // SPM Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target SPM:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Target SPM", selection: $segment.targetSPM) {
                        ForEach(10...40, id: \.self) { spm in
                            Text("\(spm) SPM").tag(spm)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
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
    @State static var previewSegment = WorkoutSegment.defaultSegment
    
    static var previews: some View {
        NavigationView {
            WorkoutSegmentConfigView(segment: $previewSegment)
        }
    }
}
