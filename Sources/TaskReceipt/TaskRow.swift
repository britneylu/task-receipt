import SwiftUI
import AppKit

// displays one task and all actions that can be performed on it
struct TaskRow: View {
    // gives the row access to task update and deletion methods
    @EnvironmentObject var store: TodoStore

    // holds the task whose information this row displays
    let task: TodoItem

    // tracks whether to show hover controls and the edit sheet
    @State private var isHovering = false
    @State private var showingEditTask = false
    @State private var editTaskHeight: CGFloat = 400

    // uses a receipt-like ink color for the row content
    private let ink = Color(
        red: 0.12,
        green: 0.11,
        blue: 0.09
    )

    // arranges the checkbox, task details, date, and delete control
    var body: some View {
        // places all task information on one horizontal row
        HStack(
            alignment: .top,
            spacing: 10
        ) {

            // toggles the task's completion state when clicked
            Button {
                store.toggleTask(task)
            } label: {
                Image(
                    systemName: "square"
                )
                .font(.system(size: 15))
                .foregroundStyle(ink)
            }
            .buttonStyle(.plain)

            // places the task title above its category
            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                // strikes through the title after the task is completed
                Text(task.title)
                    .font(
                        .system(
                            size: 12,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(ink)

                // displays the category in smaller uppercase text
                Text(task.category.uppercased())
                    .font(
                        .system(
                            size: 9,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        ink.opacity(0.5)
                    )
            }

            // pushes the due date to the row's trailing edge
            Spacer()

            // places the due date above an optional overdue warning
            VStack(
                alignment: .trailing,
                spacing: 4
            ) {

                // formats the date as an abbreviated month and day
                Text(
                    task.dueDate.formatted(
                        .dateTime
                            .month(.abbreviated)
                            .day()
                    )
                    .uppercased()
                )
                .font(
                    .system(
                        size: 10,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(ink)

                // warns about overdue tasks until they are completed
                if isOverdue {
                    Text("OVERDUE")
                        .font(
                            .system(
                                size: 8,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(
                            ink.opacity(0.65)
                        )
                }
            }

            // shows a compact delete button only while hovering over the row
            if isHovering {
                Button {
                    store.deleteTask(task)
                } label: {
                    Image(systemName: "xmark")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            ink.opacity(0.45)
                        )
                }
                .buttonStyle(.plain)
                .help("Delete task")
            }
        }
        .padding(.vertical, 11)

        // makes the full row clickable
        .contentShape(Rectangle())

        // remembers whether the pointer is currently over this row
        .onHover { hovering in
            isHovering = hovering
        }

        // click anywhere on the row to edit
        .onTapGesture {
            openEditTask()
        }

        // presents the edit form for this task
        .sheet(
            isPresented: $showingEditTask
        ) {
            EditTaskView(
                task: task,
                receiptHeight: editTaskHeight
            )
                .environmentObject(store)
        }

        // offers edit, completion, and deletion actions on right-click
        .contextMenu {

            // opens the same edit sheet as a normal row click
            Button("Edit Task") {
                openEditTask()
            }

            Divider()

            // changes its label and action based on completion state
            Button(
                "Mark Complete"
            ) {
                store.toggleTask(task)
            }

            Divider()

            // permanently removes this task from the store
            Button(
                "Delete Task",
                role: .destructive
            ) {
                store.deleteTask(task)
            }
        }
    }

    // opens the edit form with the same compact size as the add form
    private func openEditTask() {
        editTaskHeight = NSApp.keyWindow?.contentView?.bounds.height ?? 400
        showingEditTask = true
    }

    // mark: - Overdue

    // compares calendar days to avoid treating earlier times today as overdue
    private var isOverdue: Bool {
        Calendar.current.startOfDay(
            for: task.dueDate
        ) < Calendar.current.startOfDay(
            for: Date()
        )
    }
}
