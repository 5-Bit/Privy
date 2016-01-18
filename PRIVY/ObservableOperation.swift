//
//  Operation.swift
//  Michael MacCallum
//
//  Created by Michael MacCallum on 12/30/15.
//  Copyright © 2015 0x7fffffff. All rights reserved.
//

import UIKit

extension NSObject {
    public func willChangeValueForKey <RawType: RawRepresentable where RawType.RawValue == String>(key: RawType) {
        willChangeValueForKey(key.rawValue)
    }
    
    public func didChangeValueForKey <RawType: RawRepresentable where RawType.RawValue == String>(key: RawType) {
        didChangeValueForKey(key.rawValue)
    }
}

class ObservableOperation: NSOperation {
    private enum KvoKey: String, CustomStringConvertible {
        case isExecuting, isFinished, isReady, isCancelled

        var description: String {
            return self.rawValue
        }
    }

    private var _executing: Bool = false {
        willSet {
            willChangeValueForKey(KvoKey.isExecuting)
        }

        didSet {
            didChangeValueForKey(KvoKey.isExecuting)
        }
    }

    override var executing: Bool {
        get {
            return _executing
        }

        set {
            _executing = newValue
        }
    }

    private var _finished: Bool = false {
        willSet {
            willChangeValueForKey(KvoKey.isFinished)
        }

        didSet {
            didChangeValueForKey(KvoKey.isFinished)
        }
    }

    override var finished: Bool {
        get {
            return _finished
        }

        set {
            _finished = newValue

            if _finished {
                completionBlock?()
                executing = false
            }
        }
    }

    private var _cancelled: Bool = false {
        willSet {
            willChangeValueForKey(KvoKey.isCancelled)
        }

        didSet {
            didChangeValueForKey(KvoKey.isCancelled)
        }
    }

    override var cancelled: Bool {
        get {
            return _cancelled
        }

        set {
            _cancelled = newValue

            if _cancelled {
                completionBlock?()
                executing = false
            }
        }
    }
    
    override func start() {
        executing = true
    }
    
    override func cancel() {
        cancelled = true
        completionBlock?()
    }
}
