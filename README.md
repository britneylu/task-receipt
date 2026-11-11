# Task Receipt

A minimal macOS task manager that turns your to-do list into a receipt.

Task Receipt is a lightweight desktop app for tracking tasks, courses, categories, and due dates in a simple receipt-inspired interface.

> **Currently available for macOS**

## Features

- Add tasks with a name, course/category, and due date
- Quickly open the Add Task window with `Command + N`
- Edit existing tasks
- Mark tasks as complete
- Automatically move completed tasks into a History interface
- Sync completed history with Firebase Cloud Firestore
- Sign in with Google or an email and password
- Use a temporary guest session without saving history
- Restore a completed task back to the active receipt
- Delete tasks
- Automatically sort and display tasks
- Identify overdue tasks
- Automatically resize the receipt as tasks are added or removed
- Save tasks between sessions
- Native macOS interface
- Custom receipt-inspired design

## Preview

<p>
  <img src="taskreceipt.png" alt="Task Receipt Screenshot" width="350">
</p>

## Using Task Receipt

Each task contains:

- **Task** — what you need to complete
- **Course / Category** — such as `CS 1635`, `ECON 1110`, `WORK`, or `OTHER`
- **Due Date** — when the task is due

### Add a Task

Click **+ ADD TASK** at the bottom of the receipt.

You can also press **Command + N** while Task Receipt is active to open the Add Task window.

Enter the task name, course/category, and due date, then click **ADD TASK**.

### Complete a Task

Click the checkbox next to a task to mark it as complete. The task leaves the active receipt and moves into **History** with its completion date.

### View Task History

Click **HISTORY** at the bottom of the receipt to see completed tasks.

From History, click the restore arrow to return a task to the active receipt or click the trash icon to permanently delete it.

History is saved to Firebase when you use a Google or email account. Guest history lasts only for the current app session and is deleted when Task Receipt closes.

### Edit a Task

Click a task to open the edit window.

Update the task information and click **SAVE**.

You can also right-click a task and select **Edit Task**.

### Delete a Task

Hover over a task and click the **×** that appears on the right.

You can also right-click a task and select **Delete Task**.

---

## Installation

Task Receipt is currently distributed as a macOS Swift application.

> **Note:** Task Receipt is not currently signed and notarized through the Apple Developer Program. Because of this, macOS may block a prebuilt version downloaded from the internet. The recommended installation method is to build the app locally using the included build script.

### Requirements

You will need:

- macOS
- Xcode Command Line Tools
- Swift
- Git

### 1. Install the Xcode Command Line Tools

Open **Terminal** and run:

```bash
xcode-select --install
```

If they are already installed, macOS will let you know.

You can verify that Swift is available by running:

```bash
swift --version
```

### 2. Download Task Receipt

Clone the repository:

```bash
git clone https://github.com/britneylu/Receipt-Todo.git
```

Enter the project folder:

```bash
cd Receipt-Todo
```

### 3. Build and Install

Make the included build script executable:

```bash
chmod +x build-app.sh
```

Then run:

```bash
./build-app.sh
```

The script will automatically:

1. Build Task Receipt
2. Create the macOS application
3. Install `Task Receipt.app` into your Applications folder
4. Launch Task Receipt

### 4. Open Task Receipt

After the initial installation, you can open Task Receipt like a normal Mac application.

You can find it in:

- **Applications**
- **Spotlight** — press `Command + Space` and search for `Task Receipt`
- **Launchpad**
- Your **Dock**, if you choose to add it

You do not need to use Terminal every time you want to open the app.

---

## Updating Task Receipt

If you installed Task Receipt using the instructions above, open Terminal and navigate to the repository:

```bash
cd Receipt-Todo
```

Download the newest changes:

```bash
git pull
```

Then rebuild the app:

```bash
./build-app.sh
```

The newly built version will replace the previous version in your Applications folder.

---

## Running Without Installing

If you only want to test Task Receipt without installing the `.app`, you can run it directly from the project directory:

```bash
swift run
```

---

## Development

Task Receipt is built with:

- **Swift**
- **SwiftUI**
- **AppKit**
- **Swift Package Manager**
- **Firebase Authentication**
- **Firebase Cloud Firestore**

### Firebase Setup

Task Receipt works with guest history before Firebase is configured. To enable account history:

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Add an Apple app using the bundle ID `com.britney.taskreceipt`.
3. Download `GoogleService-Info.plist` and place it in the repository root beside `Package.swift`.
4. In **Authentication → Sign-in method**, enable both **Email/Password** and **Google**.
5. After enabling Google, download a fresh `GoogleService-Info.plist` so it includes the Google client and reversed client IDs.
6. Create a **Cloud Firestore** database.
7. Open **Firestore Database → Rules**, copy everything from [`firestore.rules`](firestore.rules), paste it into the editor, and click **Publish**. These rules allow signed-in users to access only their own history.

   You can alternatively deploy the same file with the Firebase CLI after running `firebase login` and `firebase use --add`:

   ```bash
   firebase deploy --only firestore:rules
   ```

8. Rebuild and install with `./build-app.sh`. The installer adds the Google callback URL scheme from `GoogleService-Info.plist`.

The History footer shows **FIREBASE SYNCED** after authentication and Firestore connect successfully. Signing into the same account on another Mac loads the same completed-task history.

Google Sign-In on macOS requires the app to be signed with an Apple-issued certificate for persistent Keychain credential storage. Email/password login and guest mode remain available while developing an unsigned build.

The main application source code is located in:

```text
Sources/TaskReceipt/
```

During development, run the project with:

```bash
swift run
```

To create and install the macOS application:

```bash
./build-app.sh
```

## Project Structure

```text
TaskReceipt/
├── Sources/
│   └── TaskReceipt/
│       ├── TaskReceiptApp.swift
│       ├── ContentView.swift
│       ├── TaskRow.swift
│       ├── HistoryView.swift
│       ├── LoginView.swift
│       ├── AccountView.swift
│       ├── AddTaskView.swift
│       ├── EditTaskView.swift
│       ├── TodoItem.swift
│       ├── TodoStore.swift
│       ├── FirebaseHistoryService.swift
│       ├── AppDelegate.swift
│       └── WindowAccessor.swift
│
├── ReceiptIcon.iconset/
├── ReceiptIcon.icns
├── ReceiptIcon.png
├── taskreceipt.png
├── Package.swift
├── firebase.json
├── firestore.rules
├── build-app.sh
├── LICENSE
└── README.md
```

## Why Task Receipt?

Task Receipt started as a small project to experiment with building a native macOS application using SwiftUI.

The goal was to create a to-do list that feels less like a traditional productivity app and more like a small object that can live on your desktop. The receipt-inspired interface provides a simple way to see what still needs to be completed without unnecessary features or clutter.
