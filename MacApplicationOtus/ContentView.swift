//
//  ContentView.swift
//  MacApplicationOtus
//
//  Created by Влад Калаев on 05.06.2021.
//

import SwiftUI

final class BackgroundExtractViewModel: ObservableObject {
    
    @Published var selectionSegment: Int = 0
    @Published var selectedSelectImage: Bool = false
    @Published var selectedImageURL: URL?
    @Published var detectionValue: String?

}

struct ContentView: View {
    
    @ObservedObject var viewModel: BackgroundExtractViewModel = backgroundExtractViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            HStack {
                Spacer()
                AVPreviewView()
                    .frame(width: 852, height: 480)
                Spacer()
            }
            Text("Detection: \(viewModel.detectionValue ?? "")" )
                .font(.title)
                .frame(width: 852, height: 20, alignment: .center)
            Button {
                viewModel.selectedSelectImage = true
            } label: {
                Text("Select Image")
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            
            Picker(selection: $viewModel.selectionSegment, label:
                    Text("")
                   , content: {
                    Text("Original").tag(0)
                    Text("Color").tag(1)
                    Text("Blur").tag(2)
                    Text("Image").tag(3)
                    Text("Detection").tag(4)
                   })
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 500)
            Spacer()
        }
        .frame(width: 1024, height: 768)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
