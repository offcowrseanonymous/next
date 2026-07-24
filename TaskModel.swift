import Foundation

/// Uma tarefa única. Sem projetos, categorias ou prioridades — só o essencial.
struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    /// Horário do dia em que a tarefa deve disparar (hora e minuto, sem data fixa — repete todo dia).
    var hour: Int
    var minute: Int
    /// Dias da semana em que a tarefa é ativa. Usa o padrão do Calendar: 1 = domingo ... 7 = sábado.
    var weekdays: Set<Int> = Set(1...7)
    /// Marca se já foi concluída "hoje". Resetado toda vez que muda o dia.
    var lastCompletedDay: String? = nil // formato "yyyy-MM-dd"

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    // Decodificação com valor padrão pra weekdays, caso existam tarefas salvas antes dessa opção existir.
    enum CodingKeys: String, CodingKey {
        case id, title, hour, minute, weekdays, lastCompletedDay
    }

    init(id: UUID = UUID(), title: String, hour: Int, minute: Int, weekdays: Set<Int> = Set(1...7), lastCompletedDay: String? = nil) {
        self.id = id
        self.title = title
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.lastCompletedDay = lastCompletedDay
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        hour = try c.decode(Int.self, forKey: .hour)
        minute = try c.decode(Int.self, forKey: .minute)
        weekdays = try c.decodeIfPresent(Set<Int>.self, forKey: .weekdays) ?? Set(1...7)
        lastCompletedDay = try c.decodeIfPresent(String.self, forKey: .lastCompletedDay)
    }

    /// Nomes curtos dos dias, na ordem do Calendar (1 = domingo ... 7 = sábado).
    static let weekdaySymbols = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    var weekdaysLabel: String {
        if weekdays.count == 7 { return "Todos os dias" }
        if weekdays == Set([2, 3, 4, 5, 6]) { return "Seg a Sex" }
        if weekdays == Set([1, 7]) { return "Fim de semana" }
        let sorted = weekdays.sorted()
        return sorted.map { Self.weekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }

    static func isToday(activeIn weekdays: Set<Int>) -> Bool {
        let today = Calendar.current.component(.weekday, from: Date())
        return weekdays.contains(today)
    }
}

/// Armazenamento simples em disco (arquivo JSON local), sem banco de dados, sem nuvem.
final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("next_tasks.json")
    }()

    init() {
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            tasks = []
            return
        }
        tasks = decoded.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    func save() {
        tasks.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        if let data = try? JSONEncoder().encode(tasks) {
            try? data.write(to: fileURL)
        }
    }

    func add(_ task: TaskItem) {
        tasks.append(task)
        save()
        NotificationManager.shared.scheduleAll(tasks: tasks)
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
        NotificationManager.shared.scheduleAll(tasks: tasks)
    }

    func markCompletedToday(_ task: TaskItem) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].lastCompletedDay = Self.todayString()
        save()
        NotificationManager.shared.scheduleAll(tasks: tasks)
    }

    static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Retorna a próxima tarefa pendente: a mais próxima (por horário) que ainda não foi concluída hoje
    /// e que está ativa no dia da semana de hoje.
    func nextPendingTask() -> TaskItem? {
        let today = Self.todayString()
        let pending = tasks.filter { $0.lastCompletedDay != today && TaskItem.isToday(activeIn: $0.weekdays) }
        guard !pending.isEmpty else { return nil }

        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)

        // Prioriza a próxima tarefa cujo horário já chegou (mais atrasada primeiro),
        // senão a próxima do dia que ainda vai chegar.
        let due = pending.filter { $0.hour * 60 + $0.minute <= nowMinutes }
        if let mostOverdue = due.min(by: { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }) {
            return mostOverdue
        }
        return pending.min { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
    }
}
