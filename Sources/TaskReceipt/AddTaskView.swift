import SwiftUI

// displays the form used to create a task
struct AddTaskView: View {

    // gives this form access to the shared list of tasks
    @EnvironmentObject var store: TodoStore

    // closes the sheet after the user cancels or adds a task
    @Environment(\.dismiss)
    private var dismiss

    // holds the values typed into the form until they are submitted
    @State private var title = ""
    @State private var category = ""
    @State private var dueDate = Date()

    // builds the complete Add Task sheet
    var body: some View {

        // places every part of the form in one vertical column
        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            // shows the form heading
            Text("NEW TASK")
                .font(.system(
                    size: 20,
                    weight: .bold,
                    design: .monospaced
                ))

            // lets the user enter the task name
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
            }

            // lets the user enter a course or category
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
            }

            // lets the user choose when the task is due
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

            // places the cancel and submit buttons on one line
            HStack {

                // closes the form without saving anything
                Button("CANCEL") {
                    dismiss()
                }

                Spacer()

                // validates and saves the new task
                Button("ADD TASK") {
                    addTask()
                }
                // makes Return submit the form
                .keyboardShortcut(
                    .defaultAction
                )
                // prevents tasks with blank names from being added
                .disabled(
                    title.trimmingCharacters(
                        in: .whitespaces
                    ).isEmpty
                )
            }
        }
        // gives the sheet consistent spacing, width, and typography
        .padding(28)
        .frame(width: 360)
        .fontDesign(.monospaced)
    }

    // cleans the form values, adds the task, and closes the sheet
    private func addTask() {

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

        // uses OTHER when no category was entered
        store.addTask(
            title: trimmedTitle,
            category:
                trimmedCategory.isEmpty
                ? "OTHER"
                : trimmedCategory,
            dueDate: dueDate
        )

        // closes the sheet after the task is saved
        dismiss()
    }
}

// reuses the same small label style for every form field
private extension Text {

    // makes a piece of text look like a form field label
    func fieldLabel() -> some View {
        self
            .font(.system(
                size: 10,
                weight: .bold,
                design: .monospaced
            ))
            .foregroundStyle(.secondary)
    }
}
