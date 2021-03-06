//
//  ChatAnimatedStickerItem.swift
//  Telegram
//
//  Created by Mikhail Filimonov on 13/05/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

import Cocoa
import TelegramCore

import SwiftSignalKit
import Postbox

final class ChatAnimatedStickerMediaLayoutParameters : ChatMediaLayoutParameters {
    let playPolicy: LottiePlayPolicy?
    let alwaysAccept: Bool?
    let cache: ASCachePurpose?
    let hidePlayer: Bool?
    let colors: [LottieColor]
    let playOnHover: Bool?
    init(playPolicy: LottiePlayPolicy?, alwaysAccept: Bool? = nil, cache: ASCachePurpose? = nil, hidePlayer: Bool = false, media: TelegramMediaFile, colors: [LottieColor] = [], playOnHover: Bool? = nil) {
        self.playPolicy = playPolicy
        self.alwaysAccept = alwaysAccept
        self.cache = cache
        self.hidePlayer = hidePlayer
        self.colors = colors
        self.playOnHover = playOnHover
        super.init(presentation: .empty, media: media, automaticDownload: true, autoplayMedia: AutoplayMediaPreferences.defaultSettings)
    }
}

class ChatAnimatedStickerItem: ChatMediaItem {
    override init(_ initialSize: NSSize, _ chatInteraction: ChatInteraction, _ context: AccountContext, _ object: ChatHistoryEntry, _ downloadSettings: AutomaticMediaDownloadSettings, theme: TelegramPresentationTheme) {
        super.init(initialSize, chatInteraction, context, object, downloadSettings, theme: theme)
        
        let mirror = renderType == .bubble && isIncoming
        parameters?.runEmojiScreenEffect = { [weak chatInteraction] emoji in
            chatInteraction?.runEmojiScreenEffect(emoji, object.message!.id, mirror, false)
        }
    }
}
