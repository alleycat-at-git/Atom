import Foundation

class AtomDispatcher<EventType: AtomEvent, GlobalState: AtomElement where GlobalState.EventType == EventType, GlobalState: AtomRoot> {
    
    private let queue: dispatch_queue_t = dispatch_queue_create("com.github.alleycat-at-git.atom", DISPATCH_QUEUE_SERIAL)
    private var subscribers: [String:AnyAtomSubscriber<EventType>] = [:]

    private let printLogQueue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    
    func dispatch(event: EventType) {
        dispatch_async(queue) { [weak self] in
            guard self != nil else { return }
            let current: GlobalState = GlobalState.instance
            let next: GlobalState = GlobalState.react(current, event: event)
            GlobalState.instance = next
            if let printQueue = self?.printLogQueue {
                dispatch_async(printQueue) { [weak self] in
                    let serializedState = next.serialize()
                    if let selfQueue = self?.queue {
                        dispatch_async(selfQueue) {
                            print(event)
                            print(serializedState)
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                guard self != nil else { return }
                self!.notify(event)
            }
        }
    }
    
    func addSubscriber<T: AtomSubscriber where T.EventType == EventType>(subscriber: T) -> String {
        let uuid = NSUUID().UUIDString
        subscribers[uuid] = AnyAtomSubscriber(subscriber)
        return uuid
    }
    
    func removeSubscriber(key: String) {
        subscribers.removeValueForKey(key)
    }
    
    
    func notify(event: EventType) {
        for (_, sub) in subscribers {
            sub.stateChanged(event)
        }
    }
}
