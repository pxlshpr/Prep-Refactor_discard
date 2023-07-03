import SwiftUI
import PhotosUI

extension PhotosPickerItem {
    func loadImage() async throws -> UIImage? {
        guard let data = try await self.loadTransferable(type: Data.self) else {
            return nil
        }
        guard let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}
