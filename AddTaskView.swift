import SwiftUI

struct AddTaskView: View {
    @ObservedObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var time: Date = Date()
    @State private var selectedWeekdays: Set<Int> = Set(1...7)

    private let presets: [(label: String, days: Set<Int>)] = [
        ("Todo dia", Set(1...7)),
        ("Seg a Sex", Set([2, 3, 4, 5, 6])),
        ("Fim de semana", Set([1, 7]))
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Tarefa") {
                    TextField("Nome da tarefa", text: $title)
                    DatePicker("Horário", selection: $time, displayedComponents: .hourAndMinute)
                }

                Section("Dias da semana") {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.label) { preset in
                            Button(preset.label) { selectedWeekdays = preset.days }
                                .font(.footnote)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedWeekdays == preset.days ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(selectedWeekdays == preset.days ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { day in
                            let isOn = selectedWeekdays.contains(day)
                            Button(TaskItem.weekdaySymbols[day - 1]) {
                                if isOn {
                                    selectedWeekdays.remove(day)
                                } else {
                                    selectedWeekdays.insert(day)
                                }
                            }
                            .font(.footnote.bold())
                            .frame(width: 40, height: 40)
                            .background(isOn ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(isOn ? .white : .primary)
                            .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }

                if !store.tasks.isEmpty {
                    Section("Tarefas cadastradas") {
                        ForEach(store.tasks) { task in
                            HStack {
                                Text(task.timeString)
                                    .foregroundColor(.secondary)
                                    .frame(width: 56, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                    Text(task.weekdaysLabel)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { store.tasks[$0] }.forEach { store.delete($0) }
                        }
                    }
                }
            }
            .navigationTitle("Nova tarefa")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedWeekdays.isEmpty)
                }
            }
        }
    }

    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let newTask = TaskItem(
            title: title.trimmingCharacters(in: .whitespaces),
            hour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            weekdays: selectedWeekdays
        )
        store.add(newTask)
        title = ""
        selectedWeekdays = Set(1...7)
        dismiss()
    }
}
