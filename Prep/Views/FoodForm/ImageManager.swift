import UIKit

struct ImageManager {
    
    static func url(for id: UUID) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("\(id.uuidString).heic")
    }
    
    static func legacyURL(for id: UUID) -> URL? {
        Bundle.main.url(forResource: id.uuidString, withExtension: "jpg")
    }
    
    static func load(_ id: UUID) -> UIImage? {
        if let image = load(url(for: id)) {
            return image
        }
        if let url = legacyURL(for: id) {
            return load(url)
        }
        return nil
    }
    
    static func delete(_ id: UUID) {
        let didDelete = delete(url(for: id))
        if !didDelete, let url = legacyURL(for: id) {
            let _ = delete(url)
        }
    }
}

extension ImageManager {
    
    static func load(_ url: URL) -> UIImage? {
        do {
            imagesLogger.debug("Loading image from URL: \(url.absoluteString, privacy: .public)")
            
            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                imagesLogger.error("Error reading image data for: \(url.absoluteString, privacy: .public)")
                return nil
            }
            imagesLogger.debug("Loaded image: \(url.absoluteString, privacy: .public)")
            return image
        } catch {
            imagesLogger.error("Error loading image: \(url.absoluteString, privacy: .public)")
            return nil
        }
    }
    
    static func delete(_ url: URL) -> Bool {
        do {
            imagesLogger.debug("Deleting image: \(url.absoluteString, privacy: .public)")
            try FileManager.default.removeItem(at: url)
            imagesLogger.debug("Deleted image: \(url.absoluteString, privacy: .public)")
            return true
        } catch {
            imagesLogger.error("Error deleting image: \(url.absoluteString, privacy: .public)")
            return false
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
