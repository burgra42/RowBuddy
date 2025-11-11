//
//  WorkoutSegment.swift
//  RowBuddy
//
//  Created by Will Olson on 7/15/25.
//
// WorkoutSegment.swift
import Foundation

struct WorkoutSegment: Identifiable, Codable {
    // CodingKeys specifies which properties should be encoded/decoded.
    // 'id' is intentionally omitted here because we want it to be generated locally,
    // not read from or written to the encoded data.
    enum CodingKeys: String, CodingKey {
        case name
        case durationSeconds
        case targetSPM
        case goalSplit
        case periodNumber
    }

    // 'id' is a let constant, as required by Identifiable.
    // It's initialized in the custom initializers below.
    let id: UUID

    var name: String
    var durationSeconds: Int // Duration of the segment in seconds
    var targetSPM: Int      // Strokes Per Minute
    var goalSplit: String   // e.g., "1:55/500m"
    var periodNumber: String // e.g., "2 of 5" or "3 of 12" for drills/intervals
    // Add any other properties you might need for a segment

    // Custom initializer for creating NEW instances programmatically.
    // A new UUID is generated automatically for these instances.
    init(name: String, durationSeconds: Int, targetSPM: Int, goalSplit: String, periodNumber: String = "") {
        self.id = UUID() // Assign a new UUID for a newly created segment
        self.name = name
        self.durationSeconds = durationSeconds
        self.targetSPM = targetSPM
        self.goalSplit = goalSplit
        self.periodNumber = periodNumber
    }

    // Custom Decodable initializer:
    // This is called automatically when Swift tries to decode a WorkoutSegment from data.
    // Since 'id' is not in CodingKeys, we explicitly generate a NEW UUID for 'id' here.
    // This ensures every decoded instance gets a unique ID for Identifiable purposes.
    init(from decoder: Decoder) throws {
        self.id = UUID() // Generate a new ID when decoding

        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        targetSPM = try container.decode(Int.self, forKey: .targetSPM)
        goalSplit = try container.decode(String.self, forKey: .goalSplit)
        periodNumber = try container.decode(String.self, forKey: .periodNumber)
    }

    // Custom Encodable method:
    // This defines how the WorkoutSegment is encoded to external data.
    // We explicitly encode only the properties listed in CodingKeys,
    // thereby skipping the 'id' property.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(targetSPM, forKey: .targetSPM)
        try container.encode(goalSplit, forKey: .goalSplit)
        try container.encode(periodNumber, forKey: .periodNumber)
    }

    // Example factory methods or default values for easier testing
    static var defaultSegment: WorkoutSegment {
        WorkoutSegment(name: "Warm Up", durationSeconds: 300, targetSPM: 20, goalSplit: "2:00/500m", periodNumber: "1 of 1")
    }
}
