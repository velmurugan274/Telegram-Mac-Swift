//
//  ChatNavigateScroller.swift
//  Telegram-Mac
//
//  Created by keepcoder on 20/10/2016.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import TelegramCore

import SwiftSignalKit
import Postbox


class ChatNavigateScroller: ImageButton {

    private let disposable:MetaDisposable = MetaDisposable()
    private var badge:BadgeNode?
    private var badgeView:View = View()
    private let context:AccountContext
    init(_ context: AccountContext, contextHolder: Atomic<ChatLocationContextHolder?>, chatLocation: ChatLocation, mode: ChatMode) {
        self.context = context
        super.init()
        autohighlight = false
        set(image: theme.icons.chatScrollUp, for: .Normal)
        set(image: theme.icons.chatScrollUpActive, for: .Highlight)
        self.setFrameSize(60,60)
        
        let unreadCount = context.chatLocationUnreadCount(for: chatLocation, contextHolder: contextHolder)
        |> deliverOnMainQueue
        
        self.disposable.set(unreadCount.start(next: { [weak self] count in
            if let strongSelf = self {
                if count > 0 {
                    strongSelf.badge = BadgeNode(.initialize(string: Int(count).prettyNumber, color: theme.colors.underSelectedColor, font: .bold(.small)), theme.colors.accent)
                    strongSelf.badge!.view = strongSelf.badgeView
                    strongSelf.badgeView.setFrameSize(strongSelf.badge!.size)
                    strongSelf.addSubview(strongSelf.badgeView)
                } else {
                    strongSelf.badgeView.removeFromSuperview()
                }
                strongSelf.needsLayout = true
            }
        }))
        
       updateLocalizationAndTheme(theme: theme)
    }
    
    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        let theme = (theme as! TelegramPresentationTheme)
        set(image: theme.icons.chatScrollUp, for: .Normal)
        set(image: theme.icons.chatScrollUpActive, for: .Highlight)
        badge?.fillColor = theme.colors.accent
        
        if theme.colors.chatBackground == theme.colors.background && theme.colors.isDark {
          

        }
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 5
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.1)
        shadow.shadowOffset = NSMakeSize(0, 2)
        self.shadow = shadow
    }
    
    override func scrollWheel(with event: NSEvent) {
        
    }
    
    override func layout() {
        super.layout()
        badgeView.centerX(y:0)
    }
    
    deinit {
        disposable.dispose()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
}
