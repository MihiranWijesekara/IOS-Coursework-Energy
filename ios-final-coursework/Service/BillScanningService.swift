//
//  BillScanningService.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import Foundation
import SwiftUI
import Combine

public final class BillScanningService: ObservableObject {
    @Published public var currentStage: ScanningStage = .recognisingText
    @Published public var isScanning: Bool = false
    @Published public var recognizedBill: BillData = .sample
    
    public init() {}
    
    public func startScanningSequence(completion: (() -> Void)? = nil) {
        isScanning = true
        currentStage = .documentDetected
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.currentStage = .recognisingText
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            self?.currentStage = .extractingData
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) { [weak self] in
            self?.currentStage = .completed
            self?.isScanning = false
            completion?()
        }
    }
    
    public func reset() {
        currentStage = .recognisingText
        isScanning = false
    }
}
