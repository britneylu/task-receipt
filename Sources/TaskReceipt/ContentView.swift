import SwiftUI
import AppKit

private struct TaskListHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ContentView: View {
    @EnvironmentObject var store: TodoStore

    @State private var showingAddTask = false
    @State private var addHover = false
    @State private var taskListContentHeight: CGFloat = 58

    // MARK: - Colors

    private let paper = Color(
        red: 0.975,
        green: 0.972,
        blue: 0.955
    )

    private let ink = Color(
        red: 0.11,
        green: 0.11,
        blue: 0.10
    )

    // Uses today's date as the receipt order number.
    // Example: September 12 -> 0912
    private var orderNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {

            header

            divider

            ScrollView {
                taskList
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: TaskListHeightKey.self,
                                value: geometry.size.height
                            )
                        }
                    }
            }
            .scrollIndicators(.automatic)
            .padding(.horizontal, -20)
            .frame(
                height: min(
                    taskListContentHeight,
                    maximumTaskListHeight
                )
            )
            .onPreferenceChange(TaskListHeightKey.self) { height in
                guard height > 0 else { return }
                taskListContentHeight = height
            }

            divider

            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .frame(width: 320)
        .background(paper)
        .foregroundStyle(ink)
        .fontDesign(.monospaced)
        .shadow(
            color: .black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 6
        )
        .background(
            WindowAccessor(
                taskCount: store.tasks.count
            )
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(store)
        }
        .focusedSceneValue(\.addTaskAction) {
            showingAddTask = true
        }
    }

    private var maximumTaskListHeight: CGFloat {
        let screen = NSApp.keyWindow?.screen ?? NSScreen.main
        return max(120, (screen?.visibleFrame.height ?? 800) - 300)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 7) {

            HStack(spacing: 8) {

                Text("✦")
                    .font(.system(size: 18))
                    .opacity(0.35)

                Text("TASK RECEIPT")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold,
                            design: .monospaced
                        )
                    )

                Text("✦")
                    .font(.system(size: 18))
                    .opacity(0.35)
            }

            Text("ORDER #\(orderNumber)")
                .font(
                    .system(
                        size: 9,
                        weight: .medium,
                        design: .monospaced
                    )
                )
                .tracking(1.5)
                .opacity(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 15)
    }

    // MARK: - Task List

    private var taskList: some View {
        VStack(spacing: 0) {

            if store.tasks.isEmpty {

                VStack(spacing: 6) {

                    Text("NO OPEN ORDERS")
                        .font(
                            .system(
                                size: 11,
                                weight: .semibold,
                                design: .monospaced
                            )
                        )

                    Text("nothing due right now")
                        .font(
                            .system(
                                size: 9,
                                design: .monospaced
                            )
                        )
                        .opacity(0.42)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)

            } else {

                ForEach(store.sortedTasks) { task in

                    TaskRow(task: task)

                    if task.id != store.sortedTasks.last?.id {
                        Rectangle()
                            .fill(ink.opacity(0.08))
                            .frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {

            HStack {

                Text("REMAINING")

                Spacer()

                Text("\(store.remainingCount)")
            }
            .font(
                .system(
                    size: 10,
                    weight: .semibold,
                    design: .monospaced
                )
            )

            // Add Task Button
            Button {
                showingAddTask = true
            } label: {

                HStack(spacing: 6) {

                    Image(systemName: "plus")
                        .font(
                            .system(
                                size: 10,
                                weight: .bold
                            )
                        )

                    Text("ADD TASK")
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            addHover
                                ? ink.opacity(0.06)
                                : Color.clear
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(
                    .easeInOut(duration: 0.15)
                ) {
                    addHover = hovering
                }
            }

            // Cute receipt footer
            VStack(spacing: 3) {

                Text("♡ ONE STEP AT A TIME ♡")
                    .font(
                        .system(
                            size: 8,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
            }
            .opacity(0.28)
            .padding(.top, 2)
        }
        .padding(.top, 12)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(ink.opacity(0.18))
            .frame(height: 1)
    }
}
