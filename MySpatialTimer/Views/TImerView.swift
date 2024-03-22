import SwiftUI

struct TimerView: View {

    var viewModel: ViewModel
    var timerManager: TimerManager
    var timerModel: TimerModel

    var body: some View {
        VStack {

            Spacer()
            Spacer()

            HStack {
                Image(systemName: "stop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .padding(.leading)
                    .opacity(timerModel.state == .stopped ? 0.1 : 1)
                    .onTapGesture {
                        if timerModel.state != .stopped {
                            timerModel.reset()
                            timerManager.cancelTimer(timerModel: timerModel)
                        }
                    }

                Spacer()
                Spacer()
                Spacer()

                ZStack {
                    Circle()
                        .opacity(0.15)
                        .foregroundColor(.gray)

                    Circle()
                        .scale(1.05)
                        .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                        .opacity(0.5)
                        .foregroundColor(.gray)

                    Circle()
                        .scale(1.05)
                        .trim(from: 0.0, to: min(timerModel.progress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                        .opacity(timerModel.state == .running || timerModel.state == .paused ? 0.8 : 0.0)
                        .foregroundColor(.blue)
                        .rotationEffect(Angle(degrees: 270.0))

                    if timerModel.state == .stopped {
                        PickerView(timerModel: timerModel)
                    } else {
                        if timerModel.displayedTimeFormat == .hr {
                            Text(timerModel.displayTimer())
                                .font(.custom("DSEG7Classic-Bold", size: 50))
                                .lineLimit(1)
                                .padding()
                        } else if timerModel.displayedTimeFormat == .min {
                            Text(timerModel.displayTimer())
                                .font(.custom("DSEG7Classic-Bold", size: 50))
                                .lineLimit(1)
                                .padding()
                        } else {
                            Text(timerModel.displayTimer())
                                .font(.custom("DSEG7Classic-Bold", size: 50))
                                .lineLimit(1)
                                .padding()
                        }
                    }
                }

                Spacer()
                Spacer()
                Spacer()

                Image(systemName: timerModel.state == .running ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .padding(.trailing)
                    .opacity(timerModel.hourSelection == 0 && timerModel.minSelection == 0 && timerModel.secSelection == 0 ? 0.1 : 1)
                    .onTapGesture {
                        if timerModel.state == .stopped {
                            timerModel.setTimer()
                        }
                        if timerModel.duration != 0 && timerModel.state != .running {
                            timerModel.start()
                            timerManager.playTimer(timerModel: timerModel)
                        } else if timerModel.state == .running {
                            timerModel.pause()
                            timerManager.pauseTimer(timerModel: timerModel)
                        }
                    }
            }

            Spacer()
            Spacer()

            HStack(spacing: 24) {
                Spacer()

                Button {
                    viewModel.removePlaceHolder(timerModelID: timerModel.id)
                } label: {
                    Image(systemName: "trash")
                }
                .frame(width: 20, height: 20)
                .opacity(timerModel.state == .running ? 0 : 1)

                Spacer()
            }
            .padding(.bottom)
        }
        .frame(width: 460, height: 400)
    }
}

//#Preview {
//    TimerView(viewModel: ViewModel(), timerManager: TimerManager(), timerModel: TimerModel())
//}
