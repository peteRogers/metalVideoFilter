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

class ViewController: UIViewController{
    var k = 0
    var incer = 1

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
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            //print("Timer fired!")
            self.k += self.incer
            if(self.k > 20 || self.k < 1){
                self.incer = self.incer * -1
            }
        }
    }
    
    
    
    
    func processVideoFrame(_ framePixelBuffer: CVPixelBuffer){
        //gets Image pixels from camera
        let inputImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
        
        //creates Kaleidescope
        let kal = CIFilter(name:"CIKaleidoscope", parameters: [kCIInputImageKey: inputImage])!
        kal.setValue(CIVector(x: inputImage.extent.width/2, y: inputImage.extent.height/2), forKey: "inputCenter")
        kal.setValue(self.k, forKey: "inputCount")
        
        let filter = SunVisualizerFilter()
        currentCIImage = filter.outputImage
        

    }
    
}
