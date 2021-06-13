//
//  DetectionSegment.swift
//  MacApplicationOtus
//
//  Created by Влад Калаев on 13.06.2021.
//

import SwiftUI
import AVFoundation
import Vision

class DetectionSegment: SegmentedRenderer {
   
    @ObservedObject var viewModel: BackgroundExtractViewModel = backgroundExtractViewModel

    override init() {
        super.init()
    }
    
    override func applyFilter() -> CVPixelBuffer? {
        
        guard let model = try? VNCoreMLModel(for: SqueezeNet().model) else { return nil }
        let request = VNCoreMLRequest(model: model) { (finishReq, err) in
            
            guard let results = finishReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            print(firstObservation.identifier,firstObservation.confidence)
            let detectionString = String(format: firstObservation.identifier,firstObservation.confidence)
           
            DispatchQueue.main.async {
                self.viewModel.detectionValue = detectionString
            }
            
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer!, options: [:]).perform([request])
        
        return pixelBuffer
    }

    
}
