import ARKit
import Observation
import QuartzCore
import RealityKit

@Observable
class ViewModel {

    private let rootEntity = Entity()
    private let arkitSession = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    private let placementLocation = Entity()

    private var anchoredObjects: [UUID: Entity] = [:]
    private var objectsBeingAnchored: [UUID: Entity] = [:]

    private var appState: AppState?
    private var timerManager: TimerManager?

    func setup(appState: AppState, timerManager: TimerManager) -> Entity {
        self.appState = appState
        self.timerManager = timerManager
        rootEntity.addChild(placementLocation)
        return rootEntity
    }

    func getTargetEntity(name: String) -> Entity? {
        return rootEntity.children.first { $0.name == name}
    }

    func addCylinder() {
        let cylinderEntity = ModelEntity(
            mesh: .generateCylinder(height: 0.01, radius: 0.3),
            materials: [SimpleMaterial(color: .init(red: 0, green: 0, blue: 1, alpha: 0.5), isMetallic: false)]
        )
        cylinderEntity.position = SIMD3<Float>(x: -0.5, y: 1.5, z: -1.0)
        let rotationQuaternionX = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let rotationQuaternionY = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        let rotationQuaternionZ = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
        cylinderEntity.orientation = rotationQuaternionX * rotationQuaternionY * rotationQuaternionZ

        rootEntity.addChild(cylinderEntity)
    }

    func addMarker() {
        let entity = ModelEntity(
            mesh: .generateCylinder(height: 0.01, radius: 0.1),
            materials: [SimpleMaterial(color: .init(red: 0, green: 0, blue: 1, alpha: 0.5), isMetallic: false)]
        )

        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: true)

        let rotationQuaternionX = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let rotationQuaternionY = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        let rotationQuaternionZ = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
        entity.orientation = rotationQuaternionX * rotationQuaternionY * rotationQuaternionZ

        placementLocation.addChild(entity)
    }

    func addPlaceHolder() {
        guard let timerManager = self.timerManager else { return }

        let timerModel = timerManager.makeTimerModel()
        timerManager.addTimerModel(timerModel: timerModel)

//        let entity = ModelEntity(
//            mesh: .generateCylinder(height: 0.01, radius: 0.1),
//            materials: [SimpleMaterial(color: .init(red: 1, green: 0, blue: 0, alpha: 1), isMetallic: false)]
//        )
//
//        entity.transform = placementLocation.transform
//
//        let rotationQuaternionX = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
//        entity.orientation *= rotationQuaternionX
//
//        rootEntity.addChild(entity)

        let entity = ModelEntity(
            mesh: .generateSphere(radius: 0),
            materials: [SimpleMaterial(color: .init(red: 1, green: 1, blue: 1, alpha: 0), isMetallic: false)]
        )

        entity.name = timerModel.id.uuidString
        entity.transform = placementLocation.transform

//        let rotationQuaternionX = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
//        let rotationQuaternionY = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
//        let rotationQuaternionZ = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
//        entity.orientation = rotationQuaternionX * rotationQuaternionY * rotationQuaternionZ

        rootEntity.addChild(entity)

        // Works only on device
//        Task {
//            await attachObjectToWorldAnchor(entity)
//        }
    }

    func removePlaceHolder(timerModelID: UUID) {
        guard let timerManager = self.timerManager,
              let timerModel = timerManager.getTargetTimerModel(id: timerModelID),
              let placeHolderEntity = getTargetEntity(name: timerModelID.uuidString) else { return }

        placeHolderEntity.removeFromParent()
        timerManager.removeTimerModel(timerModel: timerModel)
    }

    @MainActor
    func processWorldAnchorUpdates() async {
        for await anchorUpdate in worldTracking.anchorUpdates {
            process(anchorUpdate)
        }
    }

    @MainActor
    private func process(_ anchorUpdate: AnchorUpdate<WorldAnchor>) {
        let anchor = anchorUpdate.anchor

        switch anchorUpdate.event {
        case .added:
            if let objectBeingAnchored = objectsBeingAnchored[anchor.id] {
                objectsBeingAnchored.removeValue(forKey: anchor.id)
                anchoredObjects[anchor.id] = objectBeingAnchored
            } else {
                if anchoredObjects[anchor.id] == nil {
                    Task {
                        await removeAnchorWithID(anchor.id)
                    }
                }
            }
            fallthrough
        case .updated:
            if let object = anchoredObjects[anchor.id] {
                object.position = anchor.originFromAnchorTransform.translation
                object.orientation = anchor.originFromAnchorTransform.rotation
                object.isEnabled = anchor.isTracked
            }
        case .removed:
            if let object = anchoredObjects[anchor.id] {
                object.removeFromParent()
            }
            anchoredObjects.removeValue(forKey: anchor.id)
        }
    }

    private func removeAnchorWithID(_ uuid: UUID) async {
        do {
            try await worldTracking.removeAnchor(forID: uuid)
        } catch {
            //print("Failed to delete world anchor \(uuid) with error \(error).")
        }
    }

    private func attachObjectToWorldAnchor(_ object: Entity) async {
        let anchor = await WorldAnchor(originFromAnchorTransform: object.transformMatrix(relativeTo: nil))
        objectsBeingAnchored[anchor.id] = object
        do {
            try await worldTracking.addAnchor(anchor)
        } catch {
            print("Failed to add world anchor \(anchor.id) with error: \(error).")
            objectsBeingAnchored.removeValue(forKey: anchor.id)
            await object.removeFromParent()
            return
        }
    }

    // MARK: - ARKit and Anchor handlings

    @MainActor
    func runARKitSession() async {
        do {
            try await arkitSession.run([worldTracking])
        } catch {
            return
        }
    }

    @MainActor
    func processDeviceAnchorUpdates() async {
        await run(function: self.queryAndProcessLatestDeviceAnchor, withFrequency: 90)
    }

    @MainActor
    private func queryAndProcessLatestDeviceAnchor() async {
        guard worldTracking.state == .running else { return }

        placementLocation.isEnabled = appState?.isAppendMode ?? false

        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())

        guard let deviceAnchor, deviceAnchor.isTracked else { return }

        let matrix = deviceAnchor.originFromAnchorTransform
        let forward = simd_float3(0, 0, -1)
        let cameraForward = simd_act(matrix.rotation, forward)

        let front = SIMD3<Float>(x: cameraForward.x, y: cameraForward.y, z: cameraForward.z)
        let length: Float = 0.5
        let offset = length * simd_normalize(front)

        placementLocation.position = matrix.position + offset
        placementLocation.orientation = matrix.rotation
    }
}

extension ViewModel {

    @MainActor
    func run(function: () async -> Void, withFrequency hz: UInt64) async {
        while true {
            if Task.isCancelled {
                return
            }

            // Sleep for 1 s / hz before calling the function.
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / hz
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // Sleep fails when the Task is cancelled. Exit the loop.
                return
            }

            await function()
        }
    }
}
