import Foundation
import Supabase

// MARK: - Supabase Client Configuration
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // TODO: Replace these with your actual values from Supabase dashboard
        let supabaseURL = "https://pnorolvbalrodxsjjtdd.supabase.co" // e.g., https://xxxxx.supabase.co
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBub3JvbHZiYWxyb2R4c2pqdGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDU5MzQsImV4cCI6MjA3OTA4MTkzNH0.VSIrg6zEW2tm2jBw75FJqmBjqiaQahD1g9hLViC-Ti0"     // Your anon/public key
        
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User? {
        try await client.auth.session.user
    }
    
    var isSignedIn: Bool {
        client.auth.currentSession != nil
    }
    
    // MARK: - Workout Operations
    
    func saveWorkout(name: String, segments: [WorkoutSegment]) async throws -> UUID {
        guard let userId = client.auth.currentSession?.user.id else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create workout
        struct WorkoutInsert: Encodable {
            let user_id: String
            let name: String
        }
        
        let workoutData = WorkoutInsert(
            user_id: userId.uuidString,
            name: name
        )
        
        let workoutResponse: WorkoutResponse = try await client
            .from("workouts")
            .insert(workoutData)
            .select()
            .single()
            .execute()
            .value
        
        // Create segments
        struct SegmentInsert: Encodable {
            let workout_id: String
            let name: String
            let duration_seconds: Int
            let target_spm: Int
            let goal_split: String
            let period_number: String
            let position: Int
        }
        
        for (index, segment) in segments.enumerated() {
            let segmentData = SegmentInsert(
                workout_id: workoutResponse.id.uuidString,
                name: segment.name,
                duration_seconds: segment.durationSeconds,
                target_spm: segment.targetSPM,
                goal_split: segment.goalSplit,
                period_number: segment.periodNumber,
                position: index
            )
            
            try await client
                .from("workout_segments")
                .insert(segmentData)
                .execute()
        }
        
        return workoutResponse.id
    }
    
    func fetchWorkouts() async throws -> [Workout] {
        guard let userId = client.auth.currentSession?.user.id else {
            throw NSError(domain: "SupabaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Fetch workouts
        let workouts: [WorkoutResponse] = try await client
            .from("workouts")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Fetch segments for each workout
        var result: [Workout] = []
        
        for workoutResponse in workouts {
            let segments: [SegmentResponse] = try await client
                .from("workout_segments")
                .select()
                .eq("workout_id", value: workoutResponse.id.uuidString)
                .order("position", ascending: true)
                .execute()
                .value
            
            let workoutSegments = segments.map { segmentResponse in
                WorkoutSegment(
                    name: segmentResponse.name,
                    durationSeconds: segmentResponse.durationSeconds,
                    targetSPM: segmentResponse.targetSPM,
                    goalSplit: segmentResponse.goalSplit,
                    periodNumber: segmentResponse.periodNumber ?? ""
                )
            }
            
            let workout = Workout(
                id: workoutResponse.id,
                name: workoutResponse.name,
                segments: workoutSegments,
                createdDate: workoutResponse.createdAt
            )
            
            result.append(workout)
        }
        
        return result
    }
    
    func deleteWorkout(id: UUID) async throws {
        // Segments will be deleted automatically due to CASCADE
        try await client
            .from("workouts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func updateWorkout(id: UUID, name: String, segments: [WorkoutSegment]) async throws {
        // Update workout name
        struct WorkoutUpdate: Encodable {
            let name: String
            let updated_at: String
        }
        
        let workoutData = WorkoutUpdate(
            name: name,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("workouts")
            .update(workoutData)
            .eq("id", value: id.uuidString)
            .execute()
        
        // Delete existing segments
        try await client
            .from("workout_segments")
            .delete()
            .eq("workout_id", value: id.uuidString)
            .execute()
        
        // Insert new segments
        struct SegmentInsert: Encodable {
            let workout_id: String
            let name: String
            let duration_seconds: Int
            let target_spm: Int
            let goal_split: String
            let period_number: String
            let position: Int
        }
        
        for (index, segment) in segments.enumerated() {
            let segmentData = SegmentInsert(
                workout_id: id.uuidString,
                name: segment.name,
                duration_seconds: segment.durationSeconds,
                target_spm: segment.targetSPM,
                goal_split: segment.goalSplit,
                period_number: segment.periodNumber,
                position: index
            )
            
            try await client
                .from("workout_segments")
                .insert(segmentData)
                .execute()
        }
    }
}

// MARK: - Response Models
struct WorkoutResponse: Decodable {
    let id: UUID
    let name: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}

struct SegmentResponse: Decodable {
    let id: UUID
    let name: String
    let durationSeconds: Int
    let targetSPM: Int
    let goalSplit: String
    let periodNumber: String?
    let position: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationSeconds = "duration_seconds"
        case targetSPM = "target_spm"
        case goalSplit = "goal_split"
        case periodNumber = "period_number"
        case position
    }
}
