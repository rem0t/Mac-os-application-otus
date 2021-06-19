//
//  AVPreviewView.swift
//  BgLiveExtact
//
//  Created by Влад Калаев on 05.06.2021.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine

final class PreviewView: NSView {
    
    private var metalPreview: AVMetalPreviewView
    
    private var captureSession: AVCaptureSession = .init()
    private var captureDevice: AVCaptureDevice? = .default(for: .video)
    private var captureOutput: AVCaptureVideoDataOutput?
    private var captureInput: AVCaptureInput?
    
    private var bag: Set<AnyCancellable> = .init()
    
    private var predictionQueue: OperationQueue?
    private var avOutputQueue: DispatchQueue?
    private var cameraQueue: DispatchQueue?
    
    private var currentImageBuffer: CVImageBuffer?
    
    private var segmentationRenderer: SegmentedRenderer?
    private var ciContext: CIContext?
    
    init() {
        // Metal
        let mtlCmdQueue: MTLCommandQueue = MetalResourceHelper.getInstance().getCommandQueue()!
        ciContext = CIContext(mtlCommandQueue: mtlCmdQueue, options: [.cacheIntermediates: false])
        metalPreview = AVMetalPreviewView()
        
        super.init(frame: .zero)
    
        addSubview(metalPreview)
        
        disableFiltering()
        
        // Start Camera
        do {
            captureInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.beginConfiguration()
            
            if captureSession.canAddInput(captureInput!) {
                captureSession.addInput(captureInput!)
            }
            
            startCameraOutput()
        } catch {
            print("no camera")
        }
        
        backgroundExtractViewModel.$selectionSegment.sink { numSegment in
            self.changePicker(numSegment: numSegment)
        }
        .store(in: &bag)

        backgroundExtractViewModel.$selectedImageURL.sink { url in
            
            if let imgRenderer = self.segmentationRenderer as? ImageMaskSegmenter {
                //imgRenderer.selectedImgUrl = url
            }
        }
        .store(in: &bag)
    }
    
    // MARK: - CoreML + Metal
    
    func disableFiltering() {
        metalPreview.isFilteringEnabled = false
    }
    
    func enableFiltering() {
        metalPreview.isFilteringEnabled = true
        resetForFilter()
    }
    
    func changePicker(numSegment: Int) {
        
        switch numSegment {
        case 0:
            disableFiltering()
            deletePredictionQueue()
        case 1:
            segmentationRenderer = nil
            segmentationRenderer = ColorMaskSegmenter()
            enableFiltering()
        case 2:
            segmentationRenderer = nil
            segmentationRenderer = BlurMaskSegmenter()
            enableFiltering()
        case 3:
            segmentationRenderer = nil
            segmentationRenderer = ImageMaskSegmenter()
            enableFiltering()
        case 4:
            segmentationRenderer = nil
            segmentationRenderer = DetectionSegment()
            enableFiltering()
        default:
            print("Default Case")
        }
        
    }
    
    func resetForFilter() {
        deletePredictionQueue()
        createPredictionQueue()
        segmentationRenderer?.cicontext = ciContext
    }
    
    
    func createPredictionQueue() {
        predictionQueue = OperationQueue()
        predictionQueue?.maxConcurrentOperationCount = 1
    }
    
    func deletePredictionQueue() {
        predictionQueue?.isSuspended = true
        predictionQueue?.cancelAllOperations()
        predictionQueue?.isSuspended = false
        predictionQueue = nil
    }
    
    // MARK: - Camera
    
    func startCameraOutput() {
        captureOutput = AVCaptureVideoDataOutput()
        avOutputQueue = DispatchQueue(label: "avOutputQueue", qos: .userInitiated, autoreleaseFrequency: .workItem)
        
        if captureSession.canAddOutput(captureOutput!) {
         
            captureSession.addOutput(captureOutput!)
            captureOutput?.alwaysDiscardsLateVideoFrames = true
            captureOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            captureOutput?.setSampleBufferDelegate(self, queue: avOutputQueue!)
            
            let connection = captureOutput?.connection(with: .video)
            connection?.isEnabled = true
        } else {
            captureSession.commitConfiguration()
        }
        captureSession.commitConfiguration()
        
        cameraQueue = DispatchQueue(label: "CameraQueue", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
        cameraQueue?.async {
            self.captureSession.startRunning()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
 
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        currentImageBuffer = imageBuffer
        
        guard let renderer = segmentationRenderer else {
            self.metalPreview.pixelBuffer = currentImageBuffer
            return
        }
        
        var alteredPixelBuffer: CVPixelBuffer?
        if metalPreview.isFilteringEnabled {
            segmentationRenderer?.pixelBuffer = imageBuffer
            
            predictionQueue?.addOperation {
                alteredPixelBuffer = renderer.applyFilter()
                self.metalPreview.pixelBuffer = alteredPixelBuffer
            }
        } else {
            metalPreview.pixelBuffer = currentImageBuffer
        }
        
        
    }
    
}


struct AVPreviewView: NSViewRepresentable {
        
    func makeNSView(context: NSViewRepresentableContext<AVPreviewView>) -> PreviewView {
        PreviewView()
    }

    func updateNSView(_ nsView: PreviewView, context: NSViewRepresentableContext<AVPreviewView>) {
    }
}
