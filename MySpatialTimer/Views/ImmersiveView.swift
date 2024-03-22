import SwiftUI
import RealityKit

struct ImmersiveView: View {

    var appState: AppState
    var timerManager: TimerManager

    @State private var viewModel = ViewModel()

    var body: some View {

        RealityView { content, attachments in
            content.add(viewModel.setup(appState: appState, timerManager: timerManager))
            viewModel.addMarker()

            Task {
                await viewModel.runARKitSession()
            }
        } update: { update, attachments in

            for timerModel in timerManager.timerModels {
                if let attachment = attachments.entity(for: timerModel.id),
                   let placeHolder = viewModel.getTargetEntity(name: timerModel.id.uuidString) {

                    if !placeHolder.children.contains(attachment) {
                        placeHolder.addChild(attachment)
                    }
                }
            }

        } attachments: {
            ForEach(timerManager.timerModels) { timerModel in
                Attachment(id: timerModel.id) {
                    TimerView(viewModel: viewModel, timerManager: timerManager, timerModel: timerModel)
                }
            }
        }
        // Works only on device
//        .task {
//            await viewModel.processWorldAnchorUpdates()
//        }
        .task {
            await viewModel.processDeviceAnchorUpdates()
        }
        .gesture(SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { _ in
                viewModel.addPlaceHolder()
            })
    }
}

// Add cube
//            let cubeEntity = ModelEntity(
//                mesh: .generateBox(size: 0.5),
//                materials: [SimpleMaterial(color: .blue, isMetallic: false)]
//            )
//            cubeEntity.position = SIMD3<Float>(x: -0.5, y: 1.5, z: -1.0)
//            content.add(cubeEntity)

// Add cylinder
//            let cylinderEntity = ModelEntity(
//                mesh: .generateCylinder(height: 0.01, radius: 0.3),
//                materials: [SimpleMaterial(color: .blue, isMetallic: false)]
//            )
//            cylinderEntity.position = SIMD3<Float>(x: -0.5, y: 1.5, z: -1.0)
//            content.add(cylinderEntity)

// orientation
//            let cylinderEntity = ModelEntity(
//                mesh: .generateCylinder(height: 0.01, radius: 0.3),
//                materials: [SimpleMaterial(color: .init(red: 0, green: 0, blue: 1, alpha: 0.5), isMetallic: false)]
//            )
//            cylinderEntity.position = SIMD3<Float>(x: -0.5, y: 1.5, z: -1.0)
//            let rotationQuaternionX = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
//            let rotationQuaternionY = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
//            let rotationQuaternionZ = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
//            cylinderEntity.orientation = rotationQuaternionX * rotationQuaternionY * rotationQuaternionZ
//            content.add(cylinderEntity)
