import Foundation
import Postbox
import SwiftSignalKit

enum EmojiStickerSuggestionMode: Int32 {
    case none
    case all
    case installed
}

struct StickerSettings: PreferencesEntry, Equatable {
    var emojiStickerSuggestionMode: EmojiStickerSuggestionMode
    var trendingClosedOn: Int64?
    static var defaultSettings: StickerSettings {
        return StickerSettings(emojiStickerSuggestionMode: .all, trendingClosedOn: nil)
    }
    
    init(emojiStickerSuggestionMode: EmojiStickerSuggestionMode, trendingClosedOn: Int64?) {
        self.emojiStickerSuggestionMode = emojiStickerSuggestionMode
        self.trendingClosedOn = trendingClosedOn
    }
    
    init(decoder: PostboxDecoder) {
        self.emojiStickerSuggestionMode = EmojiStickerSuggestionMode(rawValue: decoder.decodeInt32ForKey("emojiStickerSuggestionMode", orElse: 0))!
        self.trendingClosedOn = decoder.decodeOptionalInt64ForKey("t.c.o")
    }
    
    func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.emojiStickerSuggestionMode.rawValue, forKey: "emojiStickerSuggestionMode")
        if let trendingClosedOn = self.trendingClosedOn {
            encoder.encodeInt64(trendingClosedOn, forKey: "t.c.o")
        }
    }
    
    func isEqual(to: PreferencesEntry) -> Bool {
        if let to = to as? StickerSettings {
            return self == to
        } else {
            return false
        }
    }
    
    func withUpdatedEmojiStickerSuggestionMode(_ emojiStickerSuggestionMode: EmojiStickerSuggestionMode) -> StickerSettings {
        return StickerSettings(emojiStickerSuggestionMode: emojiStickerSuggestionMode, trendingClosedOn: self.trendingClosedOn)
    }
    func withUpdatedTrendingClosedOn(_ trendingClosedOn: Int64?) -> StickerSettings {
        return StickerSettings(emojiStickerSuggestionMode: self.emojiStickerSuggestionMode, trendingClosedOn: trendingClosedOn)
    }
}

func updateStickerSettingsInteractively(postbox: Postbox, _ f: @escaping (StickerSettings) -> StickerSettings) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.updatePreferencesEntry(key: ApplicationSpecificPreferencesKeys.stickerSettings, { entry in
            let currentSettings: StickerSettings
            if let entry = entry as? StickerSettings {
                currentSettings = entry
            } else {
                currentSettings = StickerSettings.defaultSettings
            }
            return f(currentSettings)
        })
    }
}

func stickerSettings(postbox: Postbox) -> Signal<StickerSettings, NoError> {
    return postbox.preferencesView(keys: [ApplicationSpecificPreferencesKeys.stickerSettings]) |> map { preferencesView in
        var stickerSettings = StickerSettings.defaultSettings
        if let value = preferencesView.values[ApplicationSpecificPreferencesKeys.stickerSettings] as? StickerSettings {
            stickerSettings = value
        }
        return stickerSettings
    }
}
