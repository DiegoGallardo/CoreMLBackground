//
//  ContentView.swift
//  CoreMLBackgroundChangeSwiftUI
//
//  Created by Anupam Chugh on 27/05/21.
//

import SwiftUI
import CoreML
import CoreMedia
import Vision

struct ContentView: View {

    @State var outputImage : UIImage = UIImage(named: "unsplash")!
    @State var inputImage : UIImage = UIImage(named: "unsplash")!

    var body: some View {
        
            
            ScrollView{
                
                VStack{
                    
                    HStack{
                        
                        Image(uiImage: inputImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            
                        Spacer()
                        Image(uiImage: outputImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                    }

                    Button(action: {runVisionRequest()}, label: {
                        Text("Run Image Segmentation")
                    })
                    .padding()
                    
                }.ignoresSafeArea()
            //}
        }
    }

    func runVisionRequest() {
        
        guard let model = try? VNCoreMLModel(for: DeepLabV3(configuration: .init()).model)
        else { return }
        
        let request = VNCoreMLRequest(model: model, completionHandler: visionRequestDidComplete)
        request.imageCropAndScaleOption = .scaleFill
        DispatchQueue.global().async {

            let handler = VNImageRequestHandler(cgImage: inputImage.cgImage!, options: [:])
            
            do {
                try handler.perform([request])
            }catch {
                print(error)
            }
        }
    }
    
    func maskInputImage(){
        let bgImage = UIImage.imageFromColor(color: .orange, size: self.inputImage.size, scale: self.inputImage.scale)!

        let beginImage = CIImage(cgImage: inputImage.cgImage!)
        let background = CIImage(cgImage: bgImage.cgImage!)
        let mask = CIImage(cgImage: self.outputImage.cgImage!)
        
        if let compositeImage = CIFilter(name: "CIBlendWithMask", parameters: [
                                        kCIInputImageKey: beginImage,
                                        kCIInputBackgroundImageKey:background,
                                        kCIInputMaskImageKey:mask])?.outputImage
        {
            
            
            let ciContext = CIContext(options: nil)

            let filteredImageRef = ciContext.createCGImage(compositeImage, from: compositeImage.extent)
            
            self.inputImage = UIImage(cgImage: filteredImageRef!)
            
        }
    }

    func visionRequestDidComplete(request: VNRequest, error: Error?) {
            DispatchQueue.main.async {
                if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                    let segmentationmap = observations.first?.featureValue.multiArrayValue {
                    
                    let segmentationMask = segmentationmap.image(min: 0, max: 1)

                    self.outputImage = segmentationMask!.resizedImage(for: self.inputImage.size)!

                    maskInputImage()

                }
            }
    }
}

struct GradientPoint {
   var location: CGFloat
   var color: UIColor
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
