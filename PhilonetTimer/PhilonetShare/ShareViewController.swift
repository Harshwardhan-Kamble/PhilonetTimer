import UIKit
import Social
import UniformTypeIdentifiers

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
    
    private func saveToAppGroup(url: URL, title: String) {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) else {
            print("[ShareExtension] Failed to access App Group UserDefaults")
            return
        }
        
        var pending: [SharedArticle] = []
        if let existingData = defaults.data(forKey: AppGroupConstants.pendingArticlesKey) {
            pending = (try? JSONDecoder().decode([SharedArticle].self, from: existingData)) ?? []
        }
        
        guard !pending.contains(where: { $0.url == url }) else { return }
        
        let shared = SharedArticle(url: url, title: title, dateShared: Date())
        pending.append(shared)
        
        if let data = try? JSONEncoder().encode(pending) {
            defaults.set(data, forKey: AppGroupConstants.pendingArticlesKey)
        }
    }
}
