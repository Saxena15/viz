//
//  Home.swift
//  viz
//
//  Created by Akash Saxena on 28/06/24.
//

import SwiftUI
import VisionKit
import Vision
import PhotosUI
import AVFoundation


struct Home: View {
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State var uiImage: UIImage?
    @State private var faceObservations: [VNFaceObservation] = []
    @State var errorMessage : String = "Face was not detected"
    @State private var faces: [VNFaceObservation] = []
    var body: some View {
        
        
        
        VStack{
            
            if uiImage != nil {
                Spacer()
                Image(uiImage: uiImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .overlay(FaceBoundingBoxes(faceObservations: faceObservations, imageSize: uiImage?.size ?? .zero))
                Spacer()
            }else{
                Spacer()
            }
            Text((faceObservations.isEmpty && uiImage != nil) ? errorMessage : "\(faceObservations.count) Faces detected")
                .hidden(!(faceObservations.isEmpty && uiImage != nil))
            HStack{
                HStack{
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .any(of: [.images, .not(.livePhotos)]),
                        photoLibrary: .shared()) {
                            Text("Open Photos")
                                .foregroundColor(.white)
                                .padding()
                                .fontWeight(.medium)
                        }
                }.background(RoundedRectangle(cornerRadius: 24)
                    .fill(.cyan))
                
                HStack{
                    Text(verbatim: "Click a picture")
                        .foregroundColor(.white)
                        .padding()
                        .fontWeight(.medium)
                }.background(RoundedRectangle(cornerRadius: 24)
                    .fill(.cyan))}
            
            HStack{
                Text(verbatim: "Clear all")
                    .foregroundColor(.white)
                    .padding()
                    .fontWeight(.medium)
            }.background(RoundedRectangle(cornerRadius: 24)
                .fill(.green))
            .onTapGesture {
                self.selectedPhoto = nil
                self.uiImage = nil
            }
            
        }
        .onChange(of: selectedPhoto) { result in
            Task {
                do {
                    if let data = try await selectedPhoto?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            self.uiImage = uiImage
                            detectFaces(in: uiImage) { observations in
                                self.faceObservations = observations
                            }
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                    selectedPhoto = nil
                }
            }
        }
        
    }
    
    func detectFaces(in image: UIImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let observations = request.results as? [VNFaceObservation] {
                completion(observations)
            } else {
                completion([])
            }
        }
        
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.main.async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform request: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
        
        
    }
    
}


struct FaceBoundingBoxes: View {
    var faceObservations: [VNFaceObservation]
    var imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(faceObservations, id: \.self) { observation in
                let boundingBox = observation.boundingBox
                let size = CGSize(width: boundingBox.width * imageSize.width, height: boundingBox.height * imageSize.height)
                let origin = CGPoint(x: boundingBox.minX * imageSize.width, y: (1 - boundingBox.maxY) * imageSize.height)
                
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: size.width, height: size.height)
                    .position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
            }
        }
    }
}


extension View{
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide { hidden() }
        else { self }
    }
}

