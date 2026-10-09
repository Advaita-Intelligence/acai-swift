import Foundation

@objc(AMPStorage)
public class ObjCStorage: NSObject {
    private weak var acai: Acai?

    internal init(acai: Acai) {
        self.acai = acai
    }

    @objc
    public func getEventsStrings() -> [String] {
        guard let storage = acai?.storage else { return [] }
        return getEventsStrings(storage: storage)
    }

    @objc
    public func getInterceptedIdentifiesStrings() -> [String] {
        guard let storage = acai?.identifyStorage else { return [] }
        return getEventsStrings(storage: storage)
    }

    private func getEventsStrings(storage: Storage) -> [String] {
        guard let eventURLs: [URL] = storage.read(key: StorageKey.EVENTS) else { return [] }
        return eventURLs.map { eventURL in
            storage.getEventsString(eventBlock: eventURL)
        }.compactMap { $0 }
    }
}
