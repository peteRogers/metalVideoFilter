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
    var valueChanger1 = 0
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
        Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { _ in
            //print("Timer fired!")
            self.valueChanger1 += self.incer
            if(self.valueChanger1 > 500 || self.valueChanger1 < 1){
                self.incer = self.incer * -1
            }
        }
    }
    
    
    
    
    func processVideoFrame(_ framePixelBuffer: CVPixelBuffer){
        //gets Image pixels from camera
        let inputImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)

        
        //creates Kaleidescope
//        let kal = CIFilter(name:"CIKaleidoscope", parameters: [kCIInputImageKey: inputImage])!
//        kal.setValue(CIVector(x: inputImage.extent.width/2, y: inputImage.extent.height/2), forKey: "inputCenter")
//        kal.setValue(self.valueChanger1, forKey: "inputCount")
//        currentCIImage = kal.outputImage
        
        //creates fly eye
//        let eye = CompoundEye()
//        eye.inputImage = inputImage
//        currentCIImage = eye.outputImage
        
        //creates transverse color effect
//        let tra = TransverseChromaticAberration()
//        tra.inputImage = inputImage
//        tra.inputBlur = CGFloat(valueChanger1)
//        currentCIImage = tra.outputImage
        
        //creates sky sim
//        let sky = SunVisualizerFilter()
//        sky.inputSunAlitude = 1.0
//        currentCIImage = sky.outputImage
   
        //crt monitor simulator
//        let film = VHSTrackingLines()
//        film.inputImage = inputImage
//        //film.inputAmount = 5
//        film.inputTime = CGFloat(valueChanger1)
//
//
//        let crt = CRTFilter()
//        crt.inputImage = film.outputImage
//        currentCIImage = crt.outputImage
        
       
    }
    
}
