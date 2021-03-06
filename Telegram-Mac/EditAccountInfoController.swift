//
//  EditAccountInfoController.swift
//  Telegram
//
//  Created by Mikhail Filimonov on 26/04/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import TelegramCore

import Postbox
import SwiftSignalKit


enum EditSettingsEntryTag: ItemListItemTag {
    case bio
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? EditSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
    var stableId: InputDataEntryId {
        switch self {
        case .bio:
            return .input(_id_about)
        }
    }
}


private func valuesRequiringUpdate(state: EditInfoState, view: PeerView) -> ((fn: String, ln: String)?, about: String?) {
    if let peer = view.peers[view.peerId] as? TelegramUser {
        var names:(String, String)? = nil
        if state.firstName != peer.firstName || state.lastName != peer.lastName {
            names = (state.firstName, state.lastName)
        }
        var about: String? = nil
        
        if let cachedData = view.cachedData as? CachedUserData {
            if state.about != (cachedData.about ?? "") {
                about = state.about
            }
        }
        
        return (names, about)
    }
    return (nil, nil)
}

private final class EditInfoControllerArguments {
    let context: AccountContext
    let uploadNewPhoto:(Control)->Void
    let logout:()->Void
    let username:()->Void
    let changeNumber:()->Void
    let addAccount: ()->Void
    init(context: AccountContext, uploadNewPhoto:@escaping(Control)->Void, logout:@escaping()->Void, username: @escaping()->Void, changeNumber:@escaping()->Void, addAccount: @escaping() -> Void) {
        self.context = context
        self.logout = logout
        self.username = username
        self.changeNumber = changeNumber
        self.uploadNewPhoto = uploadNewPhoto
        self.addAccount = addAccount
    }
}
struct EditInfoState : Equatable {
    static func == (lhs: EditInfoState, rhs: EditInfoState) -> Bool {
        
        if let lhsPeer = lhs.peer, let rhsPeer = rhs.peer {
            if !lhsPeer.isEqual(rhsPeer) {
                return false
            }
        } else if (lhs.peer != nil) != (rhs.peer != nil) {
            return false
        }
        
        return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName && lhs.username == rhs.username && lhs.phone == rhs.phone && lhs.representation == rhs.representation && lhs.updatingPhotoState == rhs.updatingPhotoState && lhs.stateInited == rhs.stateInited && lhs.peerStatusSettings == rhs.peerStatusSettings
    }
    
    let firstName: String
    let lastName: String
    let about: String
    let username: String?
    let phone: String?
    let representation:TelegramMediaImageRepresentation?
    let updatingPhotoState: PeerInfoUpdatingPhotoState?
    let stateInited: Bool
    let peer: Peer?
    let peerStatusSettings: PeerStatusSettings?
    let addToException: Bool
    init(stateInited: Bool = false, firstName: String = "", lastName: String = "", about: String = "", username: String? = nil, phone: String? = nil, representation: TelegramMediaImageRepresentation? = nil, updatingPhotoState: PeerInfoUpdatingPhotoState? = nil, peer: Peer? = nil, peerStatusSettings: PeerStatusSettings? = nil, addToException: Bool = true) {
        self.firstName = firstName
        self.lastName = lastName
        self.about = about
        self.username = username
        self.phone = phone
        self.representation = representation
        self.updatingPhotoState = updatingPhotoState
        self.stateInited = stateInited
        self.peer = peer
        self.peerStatusSettings = peerStatusSettings
        self.addToException = addToException
    }
    
    init(_ peerView: PeerView) {
        let peer = peerView.peers[peerView.peerId] as? TelegramUser
        self.peer = peer
        self.firstName = peer?.firstName ?? ""
        self.lastName = peer?.lastName ?? ""
        self.username = peer?.username
        self.phone = peer?.phone
        self.about = (peerView.cachedData as? CachedUserData)?.about ?? ""
        self.representation = peer?.smallProfileImage
        self.updatingPhotoState = nil
        self.stateInited = true
        self.peerStatusSettings = (peerView.cachedData as? CachedUserData)?.peerStatusSettings
        self.addToException = true
    }
    
    func withUpdatedInited(_ stateInited: Bool) -> EditInfoState {
        return EditInfoState(stateInited: stateInited, firstName: self.firstName, lastName: self.lastName, about: self.about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: self.updatingPhotoState, peer: self.peer, peerStatusSettings: self.peerStatusSettings, addToException: self.addToException)
    }
    func withUpdatedAbout(_ about: String) -> EditInfoState {
        return EditInfoState(stateInited: self.stateInited, firstName: self.firstName, lastName: self.lastName, about: about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: self.updatingPhotoState, peer: self.peer, peerStatusSettings: self.peerStatusSettings, addToException: self.addToException)
    }
    
    
    func withUpdatedFirstName(_ firstName: String) -> EditInfoState {
        return EditInfoState(stateInited: self.stateInited, firstName: firstName, lastName: self.lastName, about: self.about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: self.updatingPhotoState, peer: self.peer, peerStatusSettings: self.peerStatusSettings, addToException: self.addToException)
    }
    func withUpdatedLastName(_ lastName: String) -> EditInfoState {
        return EditInfoState(stateInited: self.stateInited, firstName: self.firstName, lastName: lastName, about: self.about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: self.updatingPhotoState, peer: self.peer, peerStatusSettings: self.peerStatusSettings, addToException: self.addToException)
    }
    
    func withUpdatedPeerView(_ peerView: PeerView) -> EditInfoState {
        let peer = peerView.peers[peerView.peerId] as? TelegramUser
        let about = stateInited ? self.about : (peerView.cachedData as? CachedUserData)?.about ?? self.about
        let peerStatusSettings = (peerView.cachedData as? CachedUserData)?.peerStatusSettings
        return EditInfoState(stateInited: true, firstName: stateInited ? self.firstName : peer?.firstName ?? self.firstName, lastName: stateInited ? self.lastName : peer?.lastName ?? self.lastName, about: about, username: peer?.username, phone: peer?.phone, representation: peer?.smallProfileImage, updatingPhotoState: self.updatingPhotoState, peer: peer, peerStatusSettings: peerStatusSettings, addToException: self.addToException)
    }
    func withUpdatedUpdatingPhotoState(_ f: (PeerInfoUpdatingPhotoState?) -> PeerInfoUpdatingPhotoState?) -> EditInfoState {
        return EditInfoState(stateInited: self.stateInited, firstName: self.firstName, lastName: self.lastName, about: self.about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: f(self.updatingPhotoState), peer: self.peer, peerStatusSettings: self.peerStatusSettings, addToException: self.addToException)
    }
    func withoutUpdatingPhotoState() -> EditInfoState {
        return EditInfoState(stateInited: self.stateInited, firstName: self.firstName, lastName: self.lastName, about: self.about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: nil, peer:self.peer, peerStatusSettings: self.peerStatusSettings, addToException: self.addToException)
    }
    
    func withUpdatedAddToException(_ addToException: Bool) -> EditInfoState {
        return EditInfoState(stateInited: self.stateInited, firstName: self.firstName, lastName: self.lastName, about: self.about, username: self.username, phone: self.phone, representation: self.representation, updatingPhotoState: self.updatingPhotoState, peer:self.peer, peerStatusSettings: self.peerStatusSettings, addToException: addToException)
    }
}

private let _id_info = InputDataIdentifier("_id_info")
private let _id_about = InputDataIdentifier("_id_about")
private let _id_username = InputDataIdentifier("_id_username")
private let _id_phone = InputDataIdentifier("_id_phone")
private let _id_logout = InputDataIdentifier("_id_logout")
private let _id_add_account = InputDataIdentifier("_id_add_account")

private func editInfoEntries(state: EditInfoState, arguments: EditInfoControllerArguments, activeAccounts: [AccountWithInfo], updateState:@escaping ((EditInfoState)->EditInfoState)->Void) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []
    
    var sectionId: Int32 = 0
    var index: Int32 = 0
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(InputDataEntry.custom(sectionId: sectionId, index: index, value: .none, identifier: _id_info, equatable: InputDataEquatable(state), comparable: nil, item: { size, stableId -> TableRowItem in
        return EditAccountInfoItem(size, stableId: stableId, account: arguments.context.account, state: state, viewType: .singleItem, updateText: { firstName, lastName in
            updateState { current in
                return current.withUpdatedFirstName(firstName).withUpdatedLastName(lastName).withUpdatedInited(true)
            }
        }, uploadNewPhoto: { control in
            arguments.uploadNewPhoto(control)
        })
    }))
    index += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(L10n.editAccountNameDesc), data: InputDataGeneralTextData(viewType: .textBottomItem)))
    index += 1

    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(L10n.bioHeader), data: InputDataGeneralTextData(viewType: .textTopItem)))
    index += 1

    
    entries.append(.input(sectionId: sectionId, index: index, value: .string(state.about), error: nil, identifier: _id_about, mode: .plain, data: InputDataRowData(viewType: .singleItem), placeholder: nil, inputPlaceholder: L10n.bioPlaceholder, filter: {$0}, limit: 70))
    index += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(L10n.bioDescription), data: InputDataGeneralTextData(viewType: .textBottomItem)))
    index += 1
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_username, data: InputDataGeneralData(name: L10n.editAccountUsername, color: theme.colors.text, icon: nil, type: .nextContext(state.username != nil ? "@\(state.username!)" : ""), viewType: .firstItem, action: nil)))
    index += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_phone, data: InputDataGeneralData(name: L10n.editAccountChangeNumber, color: theme.colors.text, icon: nil, type: .nextContext(state.phone != nil ? formatPhoneNumber(state.phone!) : ""), viewType: .lastItem, action: nil)))
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    if activeAccounts.count < 3 {
        entries.append(InputDataEntry.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_add_account, data: InputDataGeneralData(name: L10n.editAccountAddAccount, color: theme.colors.accent, icon: nil, type: .none, viewType: .firstItem, action: {
            arguments.addAccount()
        })))
        index += 1
    }
   
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_logout, data: InputDataGeneralData(name: L10n.editAccountLogout, color: theme.colors.redUI, icon: nil, type: .none, viewType: activeAccounts.count < 3 ? .lastItem : .singleItem, action: nil)))
    index += 1
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    return entries
}


func EditAccountInfoController(context: AccountContext, focusOnItemTag: EditSettingsEntryTag? = nil, f: @escaping((ViewController)) -> Void) -> Void {
    
    let state: Promise<EditInfoState> = Promise()
    let stateValue: Atomic<EditInfoState> = Atomic(value: EditInfoState())
    let actionsDisposable = DisposableSet()
    let photoDisposable = MetaDisposable()
    let peerDisposable = MetaDisposable()
    let logoutDisposable = MetaDisposable()
    let updateNameDisposable = MetaDisposable()
    
    actionsDisposable.add(photoDisposable)
    actionsDisposable.add(peerDisposable)
    actionsDisposable.add(logoutDisposable)
    actionsDisposable.add(updateNameDisposable)
    let updateState:((EditInfoState)->EditInfoState)->Void = { f in
        state.set(.single(stateValue.modify(f)))
    }
    
    var peerView:PeerView? = nil
    
    peerDisposable.set((context.account.postbox.peerView(id: context.peerId) |> deliverOnMainQueue).start(next: { pv in
        peerView = pv
        updateState { current in
            return current.withUpdatedPeerView(pv)
        }
    }))
    
    let peerId = context.peerId
    
    let cancel = {
        photoDisposable.set(nil)
        updateState { state -> EditInfoState in
            return state.withoutUpdatingPhotoState()
        }
    }

    var close:(()->Void)? = nil
    
    let updatePhoto:(NSImage)->Void = { image in
       
        _ = (putToTemp(image: image, compress: true) |> deliverOnMainQueue).start(next: { path in
            let controller = EditImageModalController(URL(fileURLWithPath: path), settings: .disableSizes(dimensions: .square))
            showModal(with: controller, for: context.window, animationType: .scaleCenter)
            
            let updateSignal = controller.result |> map { path, _ -> TelegramMediaResource in
                return LocalFileReferenceMediaResource(localFilePath: path.path, randomId: arc4random64())
                } |> beforeNext { resource in
                    updateState { state -> EditInfoState in
                        return state.withUpdatedUpdatingPhotoState { _ in
                            return PeerInfoUpdatingPhotoState(progress: 0, cancel: cancel)
                        }
                    }
                } |> mapError {_ in return UploadPeerPhotoError.generic } |> mapToSignal { resource -> Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> in
                    return context.engine.accountData.updateAccountPhoto(resource: resource, videoResource: nil, videoStartTimestamp: nil, mapResourceToAvatarSizes: { resource, representations in
                        return mapResourceToAvatarSizes(postbox: context.account.postbox, resource: resource, representations: representations)
                    })
                } |> deliverOnMainQueue
            
            
            
            photoDisposable.set(updateSignal.start(next: { status in
                updateState { state -> EditInfoState in
                    switch status {
                    case .complete:
                        return state.withoutUpdatingPhotoState()
                    case let .progress(progress):
                        return state.withUpdatedUpdatingPhotoState { current -> PeerInfoUpdatingPhotoState? in
                            return current?.withUpdatedProgress(progress)
                        }
                    }
                }
            }, error: { error in
                updateState { state in
                    return state.withoutUpdatingPhotoState()
                }
            }, completed: {
                updateState { state -> EditInfoState in
                    return state.withoutUpdatingPhotoState()
                }
            }))
            
            controller.onClose = {
                removeFile(at: path)
            }
        })
    }
    
    let updateVideo:(Signal<VideoAvatarGeneratorState, NoError>) -> Void = { signal in
        let updateSignal: Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> = signal
        |> mapError { _ in return UploadPeerPhotoError.generic }
        |> mapToSignal { state in
            switch state {
            case .error:
                return .fail(.generic)
            case let .start(path):
                updateState { (state) -> EditInfoState in
                    return state.withUpdatedUpdatingPhotoState { previous -> PeerInfoUpdatingPhotoState? in
                        return PeerInfoUpdatingPhotoState(progress: 0, image: NSImage(contentsOfFile: path)?._cgImage, cancel: cancel)
                    }
                }
                return .next(.progress(0))
            case let .progress(value):
                return .next(.progress(value * 0.2))
            case let .complete(thumb, video, keyFrame):
                let (thumbResource, videoResource) = (LocalFileReferenceMediaResource(localFilePath: thumb, randomId: arc4random64(), isUniquelyReferencedTemporaryFile: true),
                                                      LocalFileReferenceMediaResource(localFilePath: video, randomId: arc4random64(), isUniquelyReferencedTemporaryFile: true))
                return context.engine.peers.updatePeerPhoto(peerId: peerId, photo: context.engine.peers.uploadedPeerPhoto(resource: thumbResource), video: context.engine.peers.uploadedPeerVideo(resource: videoResource) |> map(Optional.init), videoStartTimestamp: keyFrame, mapResourceToAvatarSizes: { resource, representations in
                    return mapResourceToAvatarSizes(postbox: context.account.postbox, resource: resource, representations: representations)
                }) |> map { result in
                    switch result {
                    case let .progress(current):
                        return .progress(0.2 + (current * 0.8))
                    default:
                        return result
                    }
                }
            }
        }
        photoDisposable.set(updateSignal.start(next: { status in
            updateState { state -> EditInfoState in
                switch status {
                case .complete:
                    return state.withoutUpdatingPhotoState()
                case let .progress(progress):
                    return state.withUpdatedUpdatingPhotoState { current -> PeerInfoUpdatingPhotoState? in
                        return current?.withUpdatedProgress(progress)
                    }
                }
            }
        }, error: { error in
            updateState { state in
                return state.withoutUpdatingPhotoState()
            }
        }, completed: {
            updateState { state -> EditInfoState in
                return state.withoutUpdatingPhotoState()
            }
        }))
    }
    
    let arguments = EditInfoControllerArguments(context: context, uploadNewPhoto: { control in
        
        var items:[SPopoverItem] = []
        
        items.append(.init(L10n.editAvatarPhotoOrVideo, {
            filePanel(with: photoExts + videoExts, allowMultiple: false, canChooseDirectories: false, for: context.window, completion: { paths in
                if let path = paths?.first, let image = NSImage(contentsOfFile: path) {
                    updatePhoto(image)
                } else if let path = paths?.first {
                    selectVideoAvatar(context: context, path: path, localize: L10n.videoAvatarChooseDescProfile, signal: { signal in
                        updateVideo(signal)
                    })
                }
            })
        }))
        
        items.append(.init(L10n.editAvatarStickerOrGif, { [weak control] in
            
            let controller = EntertainmentViewController(size: NSMakeSize(350, 350), context: context, mode: .selectAvatar)
            controller._frameRect = NSMakeRect(0, 0, 350, 400)
            
            let interactions = ChatInteraction(chatLocation: .peer(context.peerId), context: context)
            
            let runConvertor:(MediaObjectToAvatar)->Void = { [weak control] convertor in
                _ = showModalProgress(signal: convertor.start(), for: context.window).start(next: { [weak control] result in
                    switch result {
                    case let .image(image):
                         updatePhoto(image)
                    case let .video(path):
                        selectVideoAvatar(context: context, path: path, localize: L10n.videoAvatarChooseDescProfile, quality: AVAssetExportPresetHighestQuality, signal: { signal in
                            updateVideo(signal)
                        })
                    }
                    control?.contextObject = nil
                })
                control?.contextObject = convertor
            }
            
            interactions.sendAppFile = { file, _, _ in
                let object: MediaObjectToAvatar.Object
                if file.isAnimatedSticker {
                    object = .animated(file)
                } else if file.isSticker {
                    object = .sticker(file)
                } else {
                    object = .gif(file)
                }
                let convertor = MediaObjectToAvatar(context: context, object: object)
                runConvertor(convertor)
            }
            interactions.sendInlineResult = { [] collection, result in
                switch result {
                case let .internalReference(reference):
                    if let file = reference.file {
                        let convertor = MediaObjectToAvatar(context: context, object: .gif(file))
                        runConvertor(convertor)
                    }
                case .externalReference:
                    break
                }
            }
            
            control?.contextObject = interactions
            controller.update(with: interactions)
            if let control = control {
                showPopover(for: control, with: controller, edge: .maxY, inset: NSMakePoint(0, -110), static: true)
            }
        }))
        
        showPopover(for: control, with: SPopoverViewController(items: items), edge: .maxY, inset: NSMakePoint(0, -60))
       
    }, logout: {
        showModal(with: LogoutViewController(context: context, f: f), for: context.window)
    }, username: {
        f(UsernameSettingsViewController(context))
    }, changeNumber: {
        f(PhoneNumberIntroController(context))
    }, addAccount: {
        let testingEnvironment = NSApp.currentEvent?.modifierFlags.contains(.command) == true
        context.sharedContext.beginNewAuth(testingEnvironment: testingEnvironment)
    })
    
    let controller = InputDataController(dataSignal: combineLatest(state.get() |> deliverOnPrepareQueue, appearanceSignal |> deliverOnPrepareQueue, context.sharedContext.activeAccountsWithInfo) |> map {editInfoEntries(state: $0.0, arguments: arguments, activeAccounts: $0.2.accounts, updateState: updateState)} |> map { InputDataSignalValue(entries: $0) }, title: L10n.editAccountTitle, validateData: { data -> InputDataValidation in
        
        if let _ = data[_id_logout] {
            arguments.logout()
            return .fail(.none)
        }
        if let _ = data[_id_username] {
            arguments.username()
            return .fail(.none)
        }
        if let _ = data[_id_phone] {
            arguments.changeNumber()
            return .fail(.none)
        }
        
        return .fail(.doSomething { f in
            let current = stateValue.modify {$0}
            if current.firstName.isEmpty {
                f(.fail(.fields([_id_info : .shake])))
            }
            var signals:[Signal<Void, NoError>] = []
            if let peerView = peerView {
                let updates = valuesRequiringUpdate(state: current, view: peerView)
                if let names = updates.0 {
                    
                    signals.append(context.engine.accountData.updateAccountPeerName(firstName: names.fn, lastName: names.ln))
                }
                if let about = updates.1 {
                    signals.append(context.engine.accountData.updateAbout(about: about) |> `catch` { _ in .complete()})
                }
                updateNameDisposable.set(showModalProgress(signal: combineLatest(signals) |> deliverOnMainQueue, for: context.window).start(completed: {
                    updateState { $0 }
                    close?()
                    _ = showModalSuccess(for: context.window, icon: theme.icons.successModalProgress, delay: 1.5).start()
                }))
            }
            })
    }, updateDatas: { data in
        updateState { current in
            return current.withUpdatedAbout(data[_id_about]?.stringValue ?? "")
        }
        return .fail(.none)
    }, afterDisappear: {
        actionsDisposable.dispose()
    }, updateDoneValue: { data in
        return { f in
            let current = stateValue.modify {$0}
            if let peerView = peerView {
                let updates = valuesRequiringUpdate(state: current, view: peerView)
                f((updates.0 != nil || updates.1 != nil) ? .enabled(L10n.navigationDone) : .disabled(L10n.navigationDone))
            } else {
                f(.disabled(L10n.navigationDone))
            }
        }
    }, removeAfterDisappear: false, identifier: "account")
    
    controller.didLoaded = { controller, _ in
        if let focusOnItemTag = focusOnItemTag {
            controller.genericView.tableView.scroll(to: .center(id: focusOnItemTag.stableId, innerId: nil, animated: true, focus: .init(focus: true), inset: 0), inset: NSEdgeInsets())
        }
    }
    
    close = { [weak controller] in
        controller?.navigationController?.back()
    }
    
    f(controller)
}
