import SwiftUI

struct PickerView: View {

    @State var timerModel: TimerModel

    var minutes = [Int](0..<60)
    var seconds = [Int](0..<60)

    let width: CGFloat = 110

    var body: some View {

        @Bindable var timerModel = timerModel

        HStack {
            Spacer()

            VStack {
                Text("min")
                    .font(.title)

                Picker(selection: $timerModel.minSelection, label: Text("minute")) {
                    ForEach(0..<60) { index in
                        Text("\(self.minutes[index])")
                            .tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: width)
                .clipped()
            }

            VStack {

                Text("sec")
                    .font(.title)

                Picker(selection: $timerModel.secSelection, label: Text("second")) {
                    ForEach(0..<60) { index in
                        Text("\(self.seconds[index])")
                            .tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: width)
                .clipped()
            }

            Spacer()
        }
    }
}
