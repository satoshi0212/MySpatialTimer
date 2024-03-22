import Observation
import AudioToolbox

@Observable
class TimerManager {

    var timerModels: [TimerModel] = []
    private var timers: [String: Timer] = [:]

    func getTargetTimerModel(id: UUID) -> TimerModel? {
        return timerModels.first { $0.id == id }
    }

    func makeTimerModel() -> TimerModel {
        let timerModel = TimerModel()
        return timerModel
    }

    func addTimerModel(timerModel: TimerModel) {
        timerModels.append(timerModel)
    }

    func updateTimerModel(timerModel: TimerModel) {
        if let index = timerModels.firstIndex(of: timerModel) {
            timerModels[index] = timerModel
        } else {
            addTimerModel(timerModel: timerModel)
        }
    }

    func removeTimerModel(timerModel: TimerModel) {
        guard let index = timerModels.firstIndex(of: timerModel) else { return }
        timerModels.remove(at: index)
    }

    func playTimer(timerModel: TimerModel) {
        guard !timers.keys.contains(timerModel.id.uuidString) else { return }

        let step = 1.0 / 60.0
        let timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true, block: { _ in
            guard timerModel.state == .running else { return }

            if (timerModel.duration > 0) {
                timerModel.duration -= step
            } else {
                timerModel.state = .stopped
                if timerModel.isAlarmOn {
                    self.playSound(soundId: timerModel.soundID)
                }
            }
        })
        timers[timerModel.id.uuidString] = timer
    }

    func pauseTimer(timerModel: TimerModel) {
        guard timers.keys.contains(timerModel.id.uuidString) else { return }
        guard let timer = timers[timerModel.id.uuidString] else { return }

        timer.invalidate()
        timerModel.state = .paused
        timers.removeValue(forKey: timerModel.id.uuidString)
    }

    func cancelTimer(timerModel: TimerModel) {
        guard let timer = timers[timerModel.id.uuidString] else { return }

        timer.invalidate()
        timerModel.state = .stopped
        timers.removeValue(forKey: timerModel.id.uuidString)
    }

    // MARK: - Private

    private func playSound(soundId: SystemSoundID) {
        AudioServicesPlaySystemSound(soundId)
    }
}
