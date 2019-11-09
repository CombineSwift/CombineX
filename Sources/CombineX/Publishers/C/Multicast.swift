#if !COCOAPODS
import CXUtility
#endif

extension Publisher {
    
    public func multicast<S>(_ createSubject: @escaping () -> S) -> Publishers.Multicast<Self, S> where S : Subject, Self.Failure == S.Failure, Self.Output == S.Output {
        return .init(upstream: self, createSubject: createSubject)
    }
    
    public func multicast<S>(subject: S) -> Publishers.Multicast<Self, S> where S : Subject, Self.Failure == S.Failure, Self.Output == S.Output {
        return .init(upstream: self, createSubject: { subject })
    }
}

extension Publishers {
    
    final public class Multicast<Upstream, SubjectType> : ConnectablePublisher where Upstream : Publisher, SubjectType : Subject, Upstream.Failure == SubjectType.Failure, Upstream.Output == SubjectType.Output {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        final public let upstream: Upstream
        
        final public let createSubject: () -> SubjectType
        
        private lazy var subject: SubjectType = self.createSubject()
        
        private let lock = Lock()
        private var cancellable: Cancellable?
        
        init(upstream: Upstream, createSubject: @escaping () -> SubjectType) {
            self.upstream = upstream
            self.createSubject = createSubject
        }
        
        final public func receive<S>(subscriber: S) where S : Subscriber, SubjectType.Failure == S.Failure, SubjectType.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        /// Connects to the publisher and returns a `Cancellable` instance with which to cancel publishing.
        ///
        /// - Returns: A `Cancellable` instance that can be used to cancel publishing.
        final public func connect() -> Cancellable {
            self.lock.lock()
            defer {
                self.lock.unlock()
            }
            
            if let cancel = self.cancellable {
                return cancel
            }
            
            let cancel = self.upstream.subscribe(self.subject)
            self.cancellable = cancel
            return cancel
        }
    }
}
