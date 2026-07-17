import UIKit
import Social
import UniformTypeIdentifiers

/// Share Extension view controller that receives URLs from Safari's share sheet
/// and stores them in the App Group for the host app to pick up.
class ShareViewController: SLComposeServiceViewController {
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func didSelectPost() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        let group = DispatchGroup()
        
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                        defer { group.leave() }
                        
                        guard let url = item as? URL else { return }
                        let title = self?.contentText ?? self?.textView?.text ?? "Untitled"
                        self?.saveToAppGroup(url: url, title: title)
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
    
    // MARK: - Private
    
    private func saveToAppGroup(url: URL, title: String) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else {
            print("[ShareExtension] Failed to access App Group UserDefaults")
            return
        }
        
        // Read existing pending articles
        var pending: [SharedArticle] = []
        if let existingData = defaults.data(forKey: AppGroupConstants.pendingArticlesKey) {
            pending = (try? JSONDecoder().decode([SharedArticle].self, from: existingData)) ?? []
        }
        
        // Avoid duplicate URLs in the pending queue
        guard !pending.contains(where: { $0.url == url }) else { return }
        
        // Append the new article
        let shared = SharedArticle(url: url, title: title, dateShared: Date())
        pending.append(shared)
        
        // Save back
        if let data = try? JSONEncoder().encode(pending) {
            defaults.set(data, forKey: AppGroupConstants.pendingArticlesKey)
        }
    }
}
