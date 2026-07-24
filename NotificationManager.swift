import Foundation
import UserNotifications

/// Agenda notificações locais recorrentes (a cada 5 min) até o usuário agir.
/// Tudo local — nenhuma dependência de rede.
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let categoryId = "TASK_REMINDER"
    private let repeatIntervalMinutes = 5
    /// Por quanto tempo insistir cutucando o usuário antes de desistir (em horas).
    private let insistWindowHours = 3

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategory()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func registerCategory() {
        let start = UNNotificationAction(identifier: "START_ACTION", title: "Iniciar", options: [.foreground])
        let postpone = UNNotificationAction(identifier: "POSTPONE_ACTION", title: "Adiar", options: [])
        let skip = UNNotificationAction(identifier: "SKIP_ACTION", title: "Pular", options: [.destructive])
        let category = UNNotificationCategory(identifier: categoryId, actions: [start, postpone, skip], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Remove tudo e reagenda a partir do zero com base na lista atual de tarefas.
    func scheduleAll(tasks: [TaskItem]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let today = TaskStore.todayString()
        let pending = tasks.filter { $0.lastCompletedDay != today && TaskItem.isToday(activeIn: $0.weekdays) }
        guard let next = earliestUpcoming(pending) else { return }

        scheduleReminders(for: next)
    }

    /// Depois que o usuário Inicia/Adia/Pula, cancela os lembretes restantes daquela tarefa
    /// e agenda os da próxima pendente.
    func handledCurrentTask(remainingTasks: [TaskItem]) {
        scheduleAll(tasks: remainingTasks)
    }

    private func earliestUpcoming(_ pending: [TaskItem]) -> TaskItem? {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let due = pending.filter { $0.hour * 60 + $0.minute <= nowMinutes }
        if let mostOverdue = due.min(by: { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }) {
            return mostOverdue
        }
        return pending.min { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
    }

    private func scheduleReminders(for task: TaskItem) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        guard let firstFireDate = nextDate(hour: task.hour, minute: task.minute) else { return }

        let totalReminders = (insistWindowHours * 60) / repeatIntervalMinutes

        for i in 0..<totalReminders {
            guard let fireDate = calendar.date(byAdding: .minute, value: i * repeatIntervalMinutes, to: firstFireDate) else { continue }
            if fireDate < Date() { continue }

            let content = UNMutableNotificationContent()
            content.title = "Hora de: \(task.title)"
            content.body = i == 0 ? "Toque para iniciar, adiar ou pular." : "Ainda pendente — o que você quer fazer?"
            content.sound = .default
            content.categoryIdentifier = categoryId
            content.userInfo = ["taskId": task.id.uuidString]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "\(task.id.uuidString)_\(i)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// Próxima ocorrência de um horário (hoje se ainda não passou, senão amanhã).
    private func nextDate(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let candidate = calendar.date(from: comps) else { return nil }
        if candidate >= Date() {
            return candidate
        }
        return calendar.date(byAdding: .day, value: 0, to: candidate) // já passou hoje: dispara os reforços a partir de agora mesmo
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Mostra a notificação mesmo com o app aberto em primeiro plano.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    // Trata toques nas ações Iniciar/Adiar/Pular direto na notificação.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let taskIdString = response.notification.request.content.userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            completionHandler()
            return
        }

        NotificationCenter.default.post(
            name: .taskActionFromNotification,
            object: nil,
            userInfo: ["taskId": taskId, "action": response.actionIdentifier]
        )
        completionHandler()
    }
}

extension Notification.Name {
    static let taskActionFromNotification = Notification.Name("taskActionFromNotification")
}
