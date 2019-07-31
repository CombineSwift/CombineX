#if USE_COMBINE
import Combine
#elseif SWIFT_PACKAGE
import CombineX
#else
import Specs
#endif

enum TestSubscriptionEvent {
    case request(demand: Subscribers.Demand)
    case cancel
}

class TestSubscription: Subscription, Logging {
    
    typealias Event = TestSubscriptionEvent
    
    let name: String?
    let requestBody: ((Subscribers.Demand) -> Void)?
    let cancelBody: (() -> Void)?
    
    var isLogEnabled = false
    
    private let lock = Lock()
    private var _events: [Event] = []
    
    var events: [Event] {
        return self.lock.withLockGet(self._events)
    }
    
    init(name: String? = nil, request: ((Subscribers.Demand) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        self.name = name
        self.requestBody = request
        self.cancelBody = cancel
    }
    
    func request(_ demand: Subscribers.Demand) {
        self.log("TestSubscription-\(self.name ?? ""): request demand", demand)
        self.lock.withLock {
            self._events.append(.request(demand: demand))
        }
        self.requestBody?(demand)
    }
    
    func cancel() {
        self.log("TestSubscription-\(self.name ?? ""): cancel")
        self.lock.withLock {
            self._events.append(.cancel)
        }
        self.cancelBody?()
    }
    
    deinit {
        self.log("TestSubscription-\(self.name ?? ""): deinit")
    }
}


extension TestSubscriptionEvent: Equatable {
    
    static func == (a: TestSubscriptionEvent, b: TestSubscriptionEvent) -> Bool {
        switch (a, b) {
        case (.request(let d0), .request(let d1)):
            return d0 == d1
        case (.cancel, .cancel):
            return true
        default:
            return false
        }
    }
}
