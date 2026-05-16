import SwiftUI

struct CalendarView: View {
    @Environment(APIClient.self) private var api
    @Environment(AuthService.self) private var auth

    @State private var careLogs: [CareLogDTO] = []
    @State private var selectedMonth = Date()
    @State private var isLoading = true

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "fr_FR")
        return f
    }()

    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green600)
                }

                Text(dateFormatter.string(from: selectedMonth).capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green800)
                    .frame(maxWidth: .infinity)

                Button {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.green600)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Day headers
            HStack {
                ForEach(["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray500)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        let hasEvent = eventsForDate(date).hasEvents
                        let isToday = calendar.isDateInToday(date)
                        Text("\(calendar.component(.day, from: date))")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isToday ? Color.green600 : .clear)
                            .foregroundColor(isToday ? .white : .primary)
                            .clipShape(Circle())
                            .overlay(alignment: .bottom) {
                                if hasEvent {
                                    Circle()
                                        .fill(Color.green500)
                                        .frame(width: 5, height: 5)
                                        .offset(y: 8)
                                }
                            }
                    } else {
                        Text("")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                }
            }
            .padding(.horizontal)

            // Events for selected date
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if careLogs.isEmpty {
                Spacer()
                Text("Aucun soin enregistré ce mois")
                    .font(.subheadline)
                    .foregroundColor(.gray500)
                Spacer()
            } else {
                List(careLogs, id: \.id) { log in
                    let action = CareActionType(rawValue: log.actionType ?? "other") ?? .other
                    HStack(spacing: 10) {
                        Text(action.emoji)
                            .font(.title3)
                        VStack(alignment: .leading) {
                            Text(action.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let date = log.actionDate ?? log.createdAt,
                               let d = ISO8601DateFormatter().date(from: date) {
                                Text(d, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray400)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Calendrier")
        .task {
            await loadLogs()
        }
    }

    private func daysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: selectedMonth)!
        let firstDay = interval.start
        let weekday = calendar.component(.weekday, from: firstDay)
        // Adjust for Monday-first (weekday 1 = Sunday in Gregorian)
        let offset = (weekday + 5) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDay)!.count

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...daysInMonth {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)!
            days.append(date)
        }
        return days
    }

    private func eventsForDate(_ date: Date) -> (hasEvents: Bool, logs: [CareLogDTO]) {
        let matching = careLogs.filter { log in
            guard let dateStr = log.actionDate ?? log.createdAt,
                  let logDate = ISO8601DateFormatter().date(from: dateStr) else { return false }
            return calendar.isDate(logDate, inSameDayAs: date)
        }
        return (!matching.isEmpty, matching)
    }

    private func loadLogs() async {
        guard let user = auth.currentUser else { return }
        isLoading = true
        do {
            careLogs = try await api.careLogs(userId: user.id)
        } catch {
            careLogs = []
        }
        isLoading = false
    }
}
