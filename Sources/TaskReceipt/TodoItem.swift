import Foundation

// describes one task and supports list identity and saved JSON data
struct TodoItem: Identifiable, Codable, Equatable {
    // gives every task a permanent unique identity
    var id = UUID()

    // stores the information displayed on the receipt
    var title: String
    var category: String
    var dueDate: Date

    // tracks whether the user has completed the task
    var isCompleted: Bool = false

    // records when the task moved into history
    var completedAt: Date? = nil
}
