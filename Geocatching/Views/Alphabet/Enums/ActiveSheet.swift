import SwiftUI

enum ActiveSheet: Identifiable {
    case photoPicker, galleryPicker, cameraPicker, imageViewer
    var id: Int { hashValue }
}