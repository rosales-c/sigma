//
//  Created by: Kevin Drake & Cinthya Rosales
//

import SwiftUI
import UIKit
import CoreML
import Vision



struct ContentView: View {
    @State private var cameraRollButtonWasPressed: Bool = false
    @State private var takeAPhotoButtonWasPressed: Bool = false
    @State private var noPhotoSelected: Bool = false
    @State private var showCameraView: Bool = false
    @State private var geoImage: UIImage?
    
    
    var body: some View {
        if !noPhotoSelected {
            VStack{
                Image("LBG")
                    .resizable()
                    .ignoresSafeArea(.all)
                    .animation(.easeIn(duration: 4))
                    .overlay(CameraButtonOverlay(showCameraView: $showCameraView, takeAPhotoButtonWasPressed: $takeAPhotoButtonWasPressed, noPhotoSelected: $noPhotoSelected), alignment: .center)
                    .overlay(CameraRollOverlay(showCameraView: $showCameraView, takeAPhotoButtonWasPressed: $takeAPhotoButtonWasPressed, noPhotoSelected: $noPhotoSelected), alignment: .center)
            }
        }
        else if showCameraView {
            CaptureImageView(isShown: $showCameraView, geoImage: $geoImage, cameraOrPhotoLibrary: $takeAPhotoButtonWasPressed)
                .animation(.easeIn(duration: 4))
        }
        else {
            classifyImage()
                .animation(.easeIn(duration: 4))
        }
    }

    func classifyImage() -> some View{
        
        var imagePred: sigmaOutput = sigmaOutput(classLabelProbs: ["Error" : 0.0], classLabel: "Error")
        
        let pixel: CVPixelBuffer? = buffer(from: geoImage!)
        
        do {
            let model = try sigma(configuration: .init())
            imagePred = try
                model.prediction(image: pixel!)}
        catch {
            print("Error, select appropriate input.")
        }
        
        let retVal: [String : Double] = imagePred.classLabelProbs
        
        var arrayOfSortedValues: Array = [Double]()
        var arrayOfSortedKeys: Array = [String]()
        
        for (k,v) in (Array(retVal).sorted {$0.1 > $1.1}) {
            arrayOfSortedValues.append(v)
            arrayOfSortedKeys.append(k)
        }
        
        let classificationOfImage: String = getLabel(label: arrayOfSortedKeys[0])
        
        return VStack {
            Image("LBG")
                .resizable()
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                .overlay(VStack{
                    Image(uiImage: geoImage!)
                        .resizable()
                        .frame(width: 175, height: 175, alignment: .center)
                        .position(x: UIScreen.main.bounds.size.width/1.95, y:UIScreen.main.bounds.size.height/2.45)
                    VStack{ Text("Classification: \(classificationOfImage)")
                        Text( "Accuracy: \((arrayOfSortedValues[0]*100))%")
                        Button( action: {
                            noPhotoSelected = false
                            cameraRollButtonWasPressed = false
                            takeAPhotoButtonWasPressed = false
                            showCameraView = false
                            takeAPhotoButtonWasPressed = false
                            geoImage = nil
                        }){
                            Text("Start Over")
                                .font(.headline)
                                .padding()
                                .border(Color.black, width: 4.0)
                                .background(Color.gray)
                                .foregroundColor(Color.black)
                            
                        }
                    }
                    .position(x: UIScreen.main.bounds.size.width/1.95, y:UIScreen.main.bounds.size.height/5.45)
                })
        }
    }
    
    func getLabel(label: String) -> String {
        switch label {
//        case "Non Sigma":
//            return "Not a Sigma Clast"
        case "cw":
            return "Sigma with Clock-wise Rotation"
        case "ccw":
            return "Sigma with Counter Clock-wise Rotation"
        default:
            return "Error, Cannot Classify Image!"
        }
    }
    
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }

    
    struct CameraButtonOverlay: View {
        @Binding var showCameraView: Bool
        @Binding var takeAPhotoButtonWasPressed: Bool
        @Binding var noPhotoSelected: Bool
        
        var body: some View {
            HStack (spacing: 100){
                Button( action: {
                    print("\"Take a picture\" Button pressed")
                    self.showCameraView.toggle()
                    takeAPhotoButtonWasPressed = true
                    noPhotoSelected = true
                })
                {
                    Image("CameraIcon")
                        .resizable()
                        .frame(width: 75, height: 75, alignment: .center)
                }
                .foregroundColor(.black)
                .offset(x: 35, y: -35)
                
                Text("Take A Photo")
                    .foregroundColor(.black)
                    .offset(x: -60, y: -35)
            }
        }
    }

    struct CameraRollOverlay: View {
        @Binding var showCameraView: Bool
        @Binding var takeAPhotoButtonWasPressed: Bool
        @Binding var noPhotoSelected: Bool
        
        var body: some View {
            HStack (spacing: 100){
                Button( action: {
                    print("\"Choose a photo\" Button pressed")
                    self.showCameraView.toggle()
                    takeAPhotoButtonWasPressed = false
                    noPhotoSelected = true
                })
                {
                    Image("CameraRoll")
                        .resizable()
                        .frame(width: 75, height: 75, alignment: .center)
 
                }
                .foregroundColor(.black)
                .offset(x: 49, y: 157)
                
                Text("Choose A Photo")
                    .foregroundColor(.black)
                    .offset(x: -45, y: 170)
            }
        }
    }
}

struct CaptureImageView {
    @Binding var isShown: Bool
    @Binding var geoImage: UIImage?
    @Binding var cameraOrPhotoLibrary: Bool
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, image: $geoImage)
    }
}

extension CaptureImageView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if !cameraOrPhotoLibrary {
            picker.sourceType = .photoLibrary
            
        }
        else {
            picker.sourceType = .camera
            
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<CaptureImageView>) {
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
