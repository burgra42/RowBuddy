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
    
    // Break goal split into minutes and seconds (format: "M:SS/500m")
    private var splitMinutes: Int {
        let components = segment.goalSplit.components(separatedBy: ":")
        return Int(components.first ?? "2") ?? 2
    }
    
    private var splitSeconds: Int {
        let components = segment.goalSplit.components(separatedBy: ":")
        if components.count > 1 {
            let secondsPart = components[1].replacingOccurrences(of: "/500m", with: "")
            return Int(secondsPart) ?? 0
        }
        return 0
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
                
                // Goal Split Picker (1:30 to 3:30 per 500m)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Split:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        // Minutes picker (1-3)
                        Picker("Minutes", selection: Binding(
                            get: { splitMinutes },
                            set: { newMinutes in
                                segment.goalSplit = String(format: "%d:%02d/500m", newMinutes, splitSeconds)
                            }
                        )) {
                            ForEach(1...3, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 60)
                        .clipped()
                        
                        Text(":")
                            .font(.title2)
                        
                        // Seconds picker (00-59)
                        Picker("Seconds", selection: Binding(
                            get: { splitSeconds },
                            set: { newSeconds in
                                segment.goalSplit = String(format: "%d:%02d/500m", splitMinutes, newSeconds)
                            }
                        )) {
                            ForEach(0..<60, id: \.self) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                        
                        Text("/500m")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
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
