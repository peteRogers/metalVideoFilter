//
//  ViewController.swift
//  metalVideoFilter
//
//  Created by dt on 14/03/2022.
//

import Foundation
import UIKit
import MetalKit
import AVFoundation
import CoreImage.CIFilterBuiltins

class ViewController: UIViewController, MTKViewDelegate{
   

    @IBOutlet weak var cameraView: MTKView!{
        
            didSet {
                guard metalDevice == nil else { return }
                setupMetal()
                setupCoreImage()
                setupCaptureSession()
          
        }
    }
    
    // The Metal pipeline.
    public var metalDevice: MTLDevice!
    public var metalCommandQueue: MTLCommandQueue!
    
    // The Core Image pipeline.
    public var ciContext: CIContext!
    public var currentCIImage: CIImage? {
        didSet {
            cameraView.draw()
        }
    }
    
    // The capture session that provides video frames.
    public var session: AVCaptureSession?
    
    // MARK: - ViewController LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
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
    
    private func processVideoFrame(_ framePixelBuffer: CVPixelBuffer){
        
        let maskImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
//        let falseColor = CIFilter(name:"CIFalseColor", parameters: [kCIInputImageKey: maskImage, "inputColor0": CIColor(color: UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)),"inputColor1": CIColor(color: UIColor.init(red: 0.8, green: 0.8, blue: 0.9, alpha: 0.9)),])!
        
        let kal = CIFilter(name:"CIKaleidoscope", parameters: [kCIInputImageKey: maskImage])!
       // let glass = CIFilter(name:"CIGlassDistortion", parameters: [kCIInputImageKey: halftone2.outputImage, "inputTexture": halftone2.outputImage, "inputScale": 20])!
        kal.setValue(CIVector(x: maskImage.extent.width/2, y: maskImage.extent.height/2), forKey: "inputCenter")
       // halftone2.setValue(10, forKey: "inputAngle")
        kal.setValue(1000, forKey: "inputCount")
        
        let c = CIFilter(name: "CISunbeamsGenerator",parameters: [:])
        currentCIImage = kal.outputImage
       
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
    
}
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Grab the pixelbuffer frame from the camera output
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        processVideoFrame(pixelBuffer)
    }
}
