//
//  ContentView.swift
//  Knot
//
//  Created by Kasatani Shuntaro on 2026/05/13.
//

import SwiftUI

struct ContentView: View {
    @State var selectedThreadID: UUID?

    @State var isDeleteAlertPresented = false
    @State var threadToDelete: KnotThread?

    var body: some View {
        NavigationSplitView {
            List(KnotThreadManager.shared.threads, selection: $selectedThreadID)
            { thread in
                threadRow(thread: thread)
            }
            .navigationTitle("Threads")
            .toolbar {
                ToolbarItem {
                    Button(action: addNewThread) {
                        Label("New Thread", systemImage: "plus")
                    }
                    .help("Create a new thread")
                }
            }
        } detail: {
            if let threadID = selectedThreadID,
                let thread = KnotThreadManager.shared.threads.first(where: {
                    $0.id == threadID
                })
            {
                GeneratedUI(thread: thread)
                    .id(thread.id)
            } else {
                ContentUnavailableView(
                    "Select a Thread",
                    systemImage: "list.bullet",
                    description: Text("Start by creating a new thread")
                )
            }
        }
        .alert("Delete Thread", isPresented: $isDeleteAlertPresented) {
            Button(role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let thread = threadToDelete {
                    deleteThread(thread: thread)
                }
            }
        } message: {
            Text(
                "Are you sure you want to delete the thread \"\(threadToDelete?.title ?? "")\"?"
            )
        }
    }

    @ViewBuilder
    func threadRow(thread: KnotThread) -> some View {
        NavigationLink(value: thread.id) {
            TextField("Thread Name", text: Bindable(thread).title)
                .textFieldStyle(.plain)
                .onSubmit {
                    KnotThreadManager.shared.requestSave()
                }
        }
        .contextMenu {
            Button(role: .destructive) {
                self.isDeleteAlertPresented = true
                self.threadToDelete = thread
            } label: {
                Label("Delete Thread", systemImage: "trash")
            }
        }
        .onDeleteCommand {
            self.isDeleteAlertPresented = true
            self.threadToDelete = thread
        }
    }

    private func addNewThread() {
        // Create a new thread and add it to the array
        let newThread = KnotThread(
            title: "New Thread \(KnotThreadManager.shared.threads.count + 1)",
            components: [:],
            states: [:]
        )
        KnotThreadManager.shared.threads.append(newThread)

        // Write the threads to the disk
        KnotThreadManager.shared.requestSave()
    }

    private func deleteThread(thread: KnotThread) {
        if let index = KnotThreadManager.shared.threads.firstIndex(of: thread) {
            KnotThreadManager.shared.threads.remove(at: index)
        }

        // Write the threads to the disk
        KnotThreadManager.shared.requestSave()
    }
}

#Preview {
    ContentView()
}
