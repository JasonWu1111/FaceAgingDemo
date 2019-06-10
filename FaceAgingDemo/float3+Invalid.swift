//
//  float3+Invaild.swift
//  Predictor
//
//  Created by HuangMingxi on 2019/4/2.
//

import GLKit

extension float3 {
    func isInvalid() -> Bool {
        let null = self[0] == 0 && self[1] == 0 && self[2] == 0
//        let white = false
        let white = self[0] >= 0.99 && self[1] >= 0.99 && self[2] >= 0.99
        return null || white
    }
}
