import RealityKit

extension simd_float4x4 {

    var translation: SIMD3<Float> {
        get {
            columns.3.xyz
        }
        set {
            self.columns.3 = [newValue.x, newValue.y, newValue.z, 1]
        }
    }

    var position: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }

    var rotation: simd_quatf {
        simd_quatf(rotationMatrix)
    }

    var rotationMatrix: simd_float3x3 {
        matrix_float3x3(columns.0.xyz, columns.1.xyz, columns.2.xyz)
    }
}

extension SIMD4 {
    
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}
