import SwiftUI

struct ContentView: View {
    @StateObject private var store = TaskStore()
    @State private var runningTask: TaskItem? = nil
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil
    @State private var showingAddTask = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if let running = runningTask {
                    timerView(for: running)
                } else if let next = store.nextPendingTask() {
                    pendingView(for: next)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Next")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(store: store)
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.scheduleAll(tasks: store.tasks)
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskActionFromNotification)) { note in
            handleNotificationAction(note)
        }
    }

    // MARK: - Estados de tela

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Nenhuma tarefa pendente")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    private func pendingView(for task: TaskItem) -> some View {
        VStack(spacing: 32) {
            Spacer()
            Text(task.timeString)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(task.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            VStack(spacing: 16) {
                Button {
                    start(task)
                } label: {
                    Text("Iniciar")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                HStack(spacing: 16) {
                    Button("Adiar") { postpone(task) }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                    Button("Pular") { skip(task) }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func timerView(for task: TaskItem) -> some View {
        VStack(spacing: 32) {
            Spacer()
            Text(task.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(formattedElapsed)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
            Spacer()
            Button {
                complete(task)
            } label: {
                Text("Concluir")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Ações

    private func start(_ task: TaskItem) {
        runningTask = task
        elapsedSeconds = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
        NotificationManager.shared.scheduleAll(tasks: store.tasks) // silencia lembretes desta tarefa
    }

    private func complete(_ task: TaskItem) {
        timer?.invalidate()
        timer = nil
        runningTask = nil
        store.markCompletedToday(task)
    }

    private func postpone(_ task: TaskItem) {
        // Adiar não marca como concluída; os lembretes a cada 5 min continuam normalmente.
        NotificationManager.shared.scheduleAll(tasks: store.tasks)
    }

    private func skip(_ task: TaskItem) {
        store.markCompletedToday(task) // some por hoje, volta amanhã no mesmo horário
    }

    private func handleNotificationAction(_ note: Notification) {
        guard let taskId = note.userInfo?["taskId"] as? UUID,
              let action = note.userInfo?["action"] as? String,
              let task = store.tasks.first(where: { $0.id == taskId }) else { return }

        switch action {
        case "START_ACTION":
            start(task)
        case "SKIP_ACTION":
            skip(task)
        default:
            postpone(task)
        }
    }
}
