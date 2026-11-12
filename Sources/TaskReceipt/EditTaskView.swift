import SwiftUI

// displays a form for changing an existing task
struct EditTaskView: View {

    // gives this form access to the shared task list
    @EnvironmentObject var store: TodoStore

    // closes the sheet after the user cancels or saves
    @Environment(\.dismiss)
    private var dismiss

    // keeps the original task so its unique ID can be updated
    let task: TodoItem

    // uses the main receipt height without letting the form become too tall
    let receiptHeight: CGFloat

    // holds editable copies of the task values
    @State private var title: String
    @State private var category: String
    @State private var dueDate: Date

    // fills the form with the task's current values
    init(task: TodoItem, receiptHeight: CGFloat) {
        self.task = task
        self.receiptHeight = receiptHeight

        _title = State(initialValue: task.title)
        _category = State(initialValue: task.category)
        _dueDate = State(initialValue: task.dueDate)
    }

    // builds the complete Edit Task sheet
    var body: some View {

        // places every part of the form in one vertical column
        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            // shows the form heading
            Text("EDIT TASK")
                .font(.system(
                    size: 20,
                    weight: .bold,
                    design: .monospaced
                ))
                .foregroundStyle(.white)

            // lets the user change the task name
            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("TASK")
                    .fieldLabel()

                TextField(
                    "Problem Set 2",
                    text: $title
                )
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.white)
            }

            // lets the user change the course or category
            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("COURSE / CATEGORY")
                    .fieldLabel()

                TextField(
                    "ECON 1110",
                    text: $category
                )
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.white)
            }

            // lets the user change the due date
            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("DUE DATE")
                    .fieldLabel()

                DatePicker(
                    "",
                    selection: $dueDate,
                    displayedComponents: .date
                )
                .labelsHidden()
            }

            // places the cancel and save buttons on one line
            HStack {

                // closes the form without saving the edits
                Button("CANCEL") {
                    dismiss()
                }
                // keeps the label readable against the dark edit sheet
                .foregroundStyle(Color.white.opacity(0.85))

                Spacer()

                // saves the edited values to the matching task
                Button("SAVE") {
                    saveTask()
                }
                // makes Return save the form
                .keyboardShortcut(.defaultAction)
                // prevents the user from saving a blank task name
                .disabled(
                    title.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
        // gives the sheet consistent spacing, width, and typography
        .padding(28)
        .frame(
            width: 320,
            height: min(receiptHeight, 380)
        )
        .fontDesign(.monospaced)

        // make this sheet consistently use dark-mode controls/colors
        .preferredColorScheme(.dark)
    }

    // cleans the edited values, updates the task, and closes the sheet
    private func saveTask() {

        // removes extra whitespace from the task name
        let trimmedTitle =
            title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // removes extra whitespace from the category
        let trimmedCategory =
            category.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // updates the original task and uses OTHER for a blank category
        store.updateTask(
            id: task.id,
            title: trimmedTitle,
            category:
                trimmedCategory.isEmpty
                ? "OTHER"
                : trimmedCategory,
            dueDate: dueDate
        )

        // closes the sheet after the changes are saved
        dismiss()
    }
}

// reuses the same small label style for every edit field
private extension Text {

    // makes a piece of text look like a dark-mode field label
    func fieldLabel() -> some View {
        self
            .font(.system(
                size: 10,
                weight: .bold,
                design: .monospaced
            ))
            .foregroundStyle(
                Color.white.opacity(0.55)
            )
    }
}
