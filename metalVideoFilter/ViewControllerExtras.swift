//
//  ViewControllerExtras.swift
//  metalVideoFilter
//
//  Created by dt on 23/03/2022.
//

import Foundation
import MetalKit
import AVFoundation
import CoreImage.CIFilterBuiltins

extension ViewController: MTKViewDelegate,  AVCaptureVideoDataOutputSampleBufferDelegate{
    func draw(in view: MTKView) {
        // grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }

        // grab image
        guard let ciImage = currentCIImage else {
            return
        }

        // ensure drawable is free and not tied in the preivous drawing cycle
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        
        // make sure the image is full screen
        let drawSize = cameraView.drawableSize
        let scaleX = drawSize.width / ciImage.extent.width
        let scaleY = drawSize.height / ciImage.extent.height
        
        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        //render into the metal texture
        self.ciContext.render(newImage,
                              to: currentDrawable.texture,
                              commandBuffer: commandBuffer,
                              bounds: newImage.extent,
                              colorSpace: CGColorSpaceCreateDeviceRGB())

        // register drawwable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    func setupMetal() {
        metalDevice = MTLCreateSystemDefaultDevice()
        metalCommandQueue = metalDevice.makeCommandQueue()
        //cameraView is a metal view!!!
        cameraView.device = metalDevice
        cameraView.isPaused = true
        cameraView.enableSetNeedsDisplay = false
        cameraView.delegate = self
        cameraView.framebufferOnly = false
    }
    
    func setupCoreImage() {
        ciContext = CIContext(mtlDevice: metalDevice)
    }
    
    func setupCaptureSession() {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Error getting AVCaptureDevice.")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Error getting AVCaptureDeviceInput")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session = AVCaptureSession()
            self.session?.sessionPreset = .high
            self.session?.addInput(input)
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: .main)
            
            self.session?.addOutput(output)
            output.connections.first?.videoOrientation = .landscapeLeft
            self.session?.startRunning()
           
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Delegate method not implemented.
        print("size changed some how")
    }
    

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Grab the pixelbuffer frame from the camera output
            guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
            processVideoFrame(pixelBuffer)
    
}
}

class SunVisualizerFilter: CIFilter {
    var inputImage: CIImage?
    
    var inputSunDiameter: CGFloat = 0.1
    var inputAlbedo: CGFloat = 0.5
    var inputSunAzimuth: CGFloat = 0
    var inputSunAlitude: CGFloat = 7
    var inputSkyDarkness: CGFloat = 1.5
    var inputScattering: CGFloat = 2.5
    var inputWidth: CGFloat = 640
    var inputHeight: CGFloat = 480
    
   
    
    static var kernel: CIColorKernel = { () -> CIColorKernel in
        let url = Bundle.main.url(forResource: "skyShader",
                                  withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        return try! CIColorKernel(functionName: "skyShader",
                                  fromMetalLibraryData: data)
    }()

    override var outputImage : CIImage? {
        get {
            let extent = CGRect(x: 0, y: 0, width: inputWidth, height: inputHeight)
            
            let arguments = [inputWidth, inputHeight, inputSunDiameter, inputAlbedo, inputSunAzimuth, inputSunAlitude, inputSkyDarkness, inputScattering]
            
            let final = SunVisualizerFilter.kernel.apply(extent: extent, arguments: arguments)
            
            return final
        }
    }
    


}
