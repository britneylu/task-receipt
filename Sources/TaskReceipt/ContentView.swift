import SwiftUI
import AppKit

// passes the task list's measured height up through the SwiftUI view tree
private struct TaskListHeightKey: PreferenceKey {
    // uses zero until SwiftUI has measured the list for the first time
    static let defaultValue: CGFloat = 0

    // keeps the largest height reported during the current layout pass
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// displays the main receipt, including its header, tasks, and footer
struct ContentView: View {
    // reads and changes the shared task list
    @EnvironmentObject var store: TodoStore

    // tracks temporary interface state owned by the receipt window
    @State private var showingAddTask = false
    @State private var showingHistory = false
    @State private var showingAccount = false
    @State private var addHover = false
    @State private var historyHover = false
    @State private var accountHover = false
    @State private var taskListContentHeight: CGFloat = 58

    // mark: - Colors

    // matches the warm off-white color of receipt paper
    private let paper = Color(
        red: 0.975,
        green: 0.972,
        blue: 0.955
    )

    // provides the dark ink color used throughout the receipt
    private let ink = Color(
        red: 0.11,
        green: 0.11,
        blue: 0.10
    )

    // uses today's date as the receipt order number
    // example: September 12 -> 0912
    private var orderNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd"
        return formatter.string(from: Date())
    }

    // arranges all visible parts of the main receipt
    var body: some View {
        // stacks the header, scrolling tasks, and footer vertically
        VStack(spacing: 0) {

            // keeps the receipt identity visible above the tasks
            header

            // separates the header from the task area
            divider

            // scrolls only the tasks when they exceed the screen height
            ScrollView {
                taskList
                    // keeps row content aligned with the rest of the receipt
                    .padding(.horizontal, 20)
                    // measures the natural height of every task together
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        // reports the complete list height without drawing a view
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: TaskListHeightKey.self,
                                value: geometry.size.height
                            )
                        }
                    }
            }
            // lets macOS show the scrollbar when scrolling is possible
            .scrollIndicators(.automatic)
            // moves the scrollbar to the receipt edge while rows stay inset
            .padding(.horizontal, -20)
            // grows with the rows, stopping before it exceeds the screen
            .frame(
                height: min(
                    taskListContentHeight,
                    maximumTaskListHeight
                )
            )
            // saves each valid measurement so the scroll area can resize
            .onPreferenceChange(TaskListHeightKey.self) { height in
                guard height > 0 else { return }
                taskListContentHeight = height
            }

            // separates the task area from the receipt summary
            divider

            // keeps task count and controls visible below the scrolling rows
            footer
        }
        // gives the receipt its fixed width, spacing, colors, and shadow
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
        // connects the SwiftUI layout to the native macOS window
        .background(
            WindowAccessor(
                taskCount: store.tasks.count
            )
        )
        // presents the form when the user asks to add a task
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(store)
        }
        // presents completed tasks in a separate history interface
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .environmentObject(store)
        }
        // presents account details from the header icon
        .sheet(isPresented: $showingAccount) {
            AccountView()
                .environmentObject(store)
        }
        // requires an account choice before the receipt can be used
        .sheet(isPresented: showingLogin) {
            LoginView()
                .environmentObject(store)
        }
        // gives the focused window's Command-N menu item an action to run
        .focusedSceneValue(\.addTaskAction) {
            showingAddTask = true
        }
    }

    // leaves room for the header and footer when limiting the task list
    private var maximumTaskListHeight: CGFloat {
        // uses the active window's screen, or the main screen as a fallback
        let screen = NSApp.keyWindow?.screen ?? NSScreen.main
        return max(120, (screen?.visibleFrame.height ?? 800) - 300)
    }

    // shows login whenever no account or guest session is active
    private var showingLogin: Binding<Bool> {
        Binding(
            get: { store.accountState == .signedOut },
            set: { _ in }
        )
    }

    // mark: - Header

    // builds the centered receipt title and date-based order number
    private var header: some View {
        // keeps utility icons in the corner without moving the centered title
        ZStack(alignment: .topTrailing) {
            // places the title above the order number
            VStack(spacing: 7) {

                // places decorative stars on both sides of the title
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

                // displays today's month and day as a receipt order number
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

            // places history and account actions together in the top corner
            HStack(spacing: 3) {
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(historyHover ? ink.opacity(0.07) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("History • \(store.history.count) completed")
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        historyHover = hovering
                    }
                }

                Button {
                    handleAccountButton()
                } label: {
                    Image(systemName: accountIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(accountHoverColor)
                        )
                }
                .buttonStyle(.plain)
                .help(accountHelp)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        accountHover = hovering
                    }
                }
            }
            .foregroundStyle(ink.opacity(0.55))
        }
        .padding(.bottom, 15)
    }

    // mark: - Task List

    // builds either the empty message or all sorted task rows
    private var taskList: some View {
        // stacks rows and their separators without gaps
        VStack(spacing: 0) {

            // shows a friendly message when there are no tasks
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

                // creates one row for every task in display order
                ForEach(store.sortedTasks) { task in

                    TaskRow(task: task)

                    // draws a separator after every row except the last one
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

    // mark: - Footer

    // builds the remaining count, Add Task button, and closing message
    private var footer: some View {
        // places all footer elements in a vertical stack
        VStack(spacing: 12) {

            // shows the label and number of incomplete tasks on one line
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

            // opens the Add Task sheet when clicked
            Button {
                showingAddTask = true
            } label: {

                // combines the plus icon and button title
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
                // draws a subtle background only while the pointer hovers
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
            // animates the button's hover highlight
            .onHover { hovering in
                withAnimation(
                    .easeInOut(duration: 0.15)
                ) {
                    addHover = hovering
                }
            }

            // displays a small encouraging message at the receipt's bottom
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

    // draws the account hover color only while the pointer is over it
    private var accountHoverColor: Color {
        accountHover ? ink.opacity(0.07) : Color.clear
    }

    // chooses an account icon that reflects the current session
    private var accountIcon: String {
        switch store.accountState {
        case .loading:
            return "person.crop.circle.badge.clock"
        case .signedOut:
            return "person.crop.circle.badge.plus"
        case .guest:
            return "person.crop.circle"
        case .signedIn:
            return "person.crop.circle.fill"
        }
    }

    // explains the account icon action when the pointer hovers over it
    private var accountHelp: String {
        switch store.accountState {
        case .loading:
            return "Connecting account"
        case .signedOut:
            return "Sign in"
        case .guest:
            return "Guest • sign in to save history"
        case .signedIn(let name):
            return "\(name) • sign out"
        }
    }

    // performs the action represented by the account icon
    private func handleAccountButton() {
        switch store.accountState {
        case .guest, .signedIn:
            showingAccount = true
        case .loading, .signedOut:
            break
        }
    }

    // mark: - Divider

    // draws the thin horizontal rule used between receipt sections
    private var divider: some View {
        Rectangle()
            .fill(ink.opacity(0.18))
            .frame(height: 1)
    }
}
