import UIKit

struct ImageManager {
    static func url(for id: UUID) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("\(id.uuidString).heic")
    }
    
    static func load(_ id: UUID) async -> UIImage? {
        do {
            imagesLogger.debug("Loading image: \(id, privacy: .public)")
            let data = try Data(contentsOf: url(for: id))
            guard let image = UIImage(data: data) else {
                imagesLogger.error("Error reading image data for: \(id, privacy: .public)")
                return nil
            }
            imagesLogger.debug("Loaded image: \(id, privacy: .public)")
            return image
        } catch {
            imagesLogger.error("Error loading image: \(id, privacy: .public)")
            return nil
        }
    }

    static func delete(_ id: UUID) {
        do {
            imagesLogger.debug("Deleting image: \(id, privacy: .public)")
            try FileManager.default.removeItem(at: url(for: id))
            imagesLogger.debug("Deleted image: \(id, privacy: .public)")
        } catch {
            imagesLogger.error("Error deleting image: \(id, privacy: .public)")
        }
    }

    static func save(image: UIImage, id: UUID) {
        guard let data = image.heicData() else {
            imagesLogger.error("Couldn't get HEIC data for image: \(id, privacy: .public)")
            return
        }
        do {
            imagesLogger.debug("Saving image: \(id, privacy: .public)")
            try data.write(to: url(for: id))
            imagesLogger.debug("Image saved: \(id, privacy: .public)")
        } catch {
            imagesLogger.error("Error saving image: \(id, privacy: .public)")
        }
    }
}
