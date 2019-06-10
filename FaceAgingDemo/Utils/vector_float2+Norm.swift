//
//  vector_float2+float3.swift
//  Predictor
//
//  Created by Jason Wu on 2019/4/2.
//

import GLKit

extension vector_float2 {
    
    func squaredNorm() -> Float {
        return self.x * self.x + self.y * self.y
    }
    
    func norm() -> Float {
        return self.squaredNorm().squareRoot()
    }
    
    func normalized() -> vector_float2 {
        if (self.norm() == 0) {
            return self
        } else {
            return self / self.norm()
        }
    }
}

