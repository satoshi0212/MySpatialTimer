import AudioToolbox

@Observable
class TimerModel: Identifiable, Equatable, Codable, Hashable {

    var id: UUID = UUID()
    var state: TimerState = .stopped

    var displayedTimeFormat: TimeFormat = .min

    var hourSelection: Int = 0
    var minSelection: Int = 0
    var secSelection: Int = 0
    var duration: Double = 0
    var maxValue: Double = 0

    var soundID: SystemSoundID = 1151
    var soundName: String = "Beat"

    var isAlarmOn: Bool = true

    static func == (lhs: TimerModel, rhs: TimerModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func setTimer() {
        duration = Double(hourSelection * 3600 + minSelection * 60 + secSelection)
        maxValue = duration

        if duration < 60 {
            displayedTimeFormat = .sec // 00:00
        } else if duration < 3600 {
            displayedTimeFormat = .min // 00:00
        } else {
            displayedTimeFormat = .hr  // 00:00:00
        }
    }

    func displayTimer() -> String {
        let hr = Int(duration) / 3600
        let min = Int(duration) % 3600 / 60
        let sec = Int(duration) % 3600 % 60

        switch displayedTimeFormat {
        case .hr:
            return String(format: "%02d:%02d:%02d", hr, min, sec)
        case .min:
            return String(format: "%02d:%02d", min, sec)
        case .sec:
            return String(format: "%02d:%02d", min, sec)
        }
    }

    func start() {
        state = .running
    }

    func pause() {
        state = .paused
    }

    func reset() {
        state = .stopped
        duration = 0
    }

    var progress: CGFloat {
        return 1.0 - duration / maxValue
    }
}

enum TimerState: String, Codable {
    case running
    case paused
    case stopped
}

enum TimeFormat: Codable {
    case hr
    case min
    case sec
}
