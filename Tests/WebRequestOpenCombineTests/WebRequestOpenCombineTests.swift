import XCTest
import Dispatch
import WebRequest
import OpenCombine
import LittleWebServer
@testable import WebRequestOpenCombine

#if swift(>=4.1)
    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif
#endif


final class WebRequestOpenCombineTests: XCTestCase {
    static var server: LittleWebServer!
    
    public static var testURLBase: URL {
        
        var urlBase = self.server.listeners.first(as: LittleWebServerTCPIPListener.self)!.url
        if urlBase.host == "0.0.0.0" {
            var urlString = urlBase.absoluteString
            urlString = urlString.replacingOccurrences(of: "0.0.0.0", with: "127.0.0.1")
            urlBase = URL(string: urlString)!
        }
        
        return urlBase
    }
    
    static var testURLSearch: URL {
        return URL(string: "/search", relativeTo: testURLBase)!
    }
    var testURLBase: URL { return WebRequestOpenCombineTests.testURLBase }
    var testURLSearch: URL { return WebRequestOpenCombineTests.testURLSearch }
    
    static var uploadedData: [String: Data] = [:]
    var uploadedData: [String: Data] { return WebRequestOpenCombineTests.uploadedData }
    
    
    override class func setUp() {
        super.setUp()
        
        var retryCount: Int = 0
        var retry: Bool = true
        repeat {
            do {
                let listener = try LittleWebServerHTTPListener(specificIP: .anyIPv4,
                                                               port: .firstAvailable,
                                                               reuseAddr: true,
                                                               maxBacklogSize: LittleWebServerSocketListener.DEFAULT_MAX_BACK_LOG_SIZE,
                                                               enablePortSharing: true)
                
                WebRequestOpenCombineTests.server = LittleWebServer(listener)
                retry = false
            } catch LittleWebServerSocketConnection.SocketError.socketBindFailed(let error) {
                if let sysError = error as? LittleWebServerSocketSystemError,
                   sysError == .addressAlreadyInUse && retryCount < 3 {
                    retryCount += 1
                } else {
                    print("Failed to create listener: \(error)")
                    retry = false
                }
            } catch {
                print("Failed to create listener: \(error)")
                retry = false
            }
        } while retry
        
        
        WebRequestOpenCombineTests.server?.defaultHost["/search"] = {
            (request: LittleWebServer.HTTP.Request) -> LittleWebServer.HTTP.Response in
            let initialValue = "Query"
            var rtn: String = initialValue
            
            // Allow the client to slow down the response
            if let q = request.queryItems.first(where: { return $0.name == "sleep" }),
               let qValue = q.value,
               let dValue = Double(qValue) {
                Thread.sleep(forTimeInterval: dValue)
            }
            
            if let param = request.queryItems.first(where: { return $0.name == "q" }) {
                if rtn == initialValue { rtn += "?" }
                else { rtn += "&"}
                
                rtn += "q=" + (param.value ?? "")
            }
            if let param = request.queryItems.first(where: { return $0.name == "start" }) {
                if rtn == initialValue { rtn += "?" }
                else { rtn += "&"}
                
                rtn += "start=" + (param.value ?? "")
            }
            return .ok(body: .plainText(rtn))
        }
        
        let eventPrefixData = "{ \"event_type\": \"system\", \"event_count\": ".data(using: .utf8)!
        let eventSuffixData = ", \"event_up\": true }\n".data(using: .utf8)!
        
        WebRequestOpenCombineTests.server?.defaultHost["/events"] = { (request: LittleWebServer.HTTP.Request) -> LittleWebServer.HTTP.Response in
            
            var sleepValue: Double? = nil
            // Allow the client to slow down the response
            if let q = request.queryItems.first(where: { return $0.name == "sleep" }),
               let qValue = q.value,
               let dValue = Double(qValue) {
                sleepValue = dValue
            }
            
            func eventWriter(_ input: LittleWebServerInputStream, _ output: LittleWebServerOutputStream) {
                var count: Int = 0
                while self.server.isRunning &&
                      output.isConnected &&
                      count < Int.max {
                    
                    count += 1
                    //let dta = eventData.data(using: .utf8)!
                    
                    do {
                        #if _runtime(_ObjC)
                        try autoreleasepool {
                            let coutData = "\(count)".data(using: .utf8)!
                            try output.write( eventPrefixData + coutData + eventSuffixData)
                        }
                        #else
                        let coutData = "\(count)".data(using: .utf8)!
                        try output.write( eventPrefixData + coutData + eventSuffixData)
                        #endif
                    } catch {
                        if output.isConnected {
                            XCTFail("OH NO: \(error)")
                        }
                        break
                    }
                    if let s = sleepValue {
                        Thread.sleep(forTimeInterval: s)
                    }
                }
                if output.isConnected {
                    // If we're still connected we send a 0 byte line
                    // to indicate that response has ended
                    try? output.write([])
                }
            }
            
            return .ok(body: .custom(eventWriter))
        }
        
        #if swift(>=5.3)
        let webRequestTestFolder = NSString(string: "\(#filePath)").deletingLastPathComponent
        #else
        let webRequestTestFolder = NSString(string: "\(#file)").deletingLastPathComponent
        #endif
        print("Sharing folder '\(webRequestTestFolder)' at '/testfiles'")
        WebRequestOpenCombineTests.server?.defaultHost.get["/testfiles/"] = LittleWebServer.FSSharing.share(resource: URL(fileURLWithPath: webRequestTestFolder))

        WebRequestOpenCombineTests.server?.defaultHost.post["/upload"] = { (request: LittleWebServer.HTTP.Request,
                                                     routeController: LittleWebServer.Routing.Requests.RouteController) -> LittleWebServer.HTTP.Response in
            do {
                if request.uploadedFiles.count > 0 {
                    for file in request.uploadedFiles {
                        self.uploadedData[file.path] = try Data.init(contentsOf: file.location)
                    }
                } else if let contentLength = request.contentLength,
                          contentLength > 0 {
                    self.uploadedData[""] = try request.inputStream.read(exactly: Int(contentLength))
                }
                return .ok(body: .empty)
            } catch {
                return routeController.internalError(for: request,
                                                     error: error,
                                                     message: "Failed to load uploaded data")
            }
        }
        
        
        do {
            try WebRequestOpenCombineTests.server?.start()
            print("Server started")
        } catch {
            print("Failed to start server")
        }
    }
    override class func tearDown() {
        print("Stopping server")
        WebRequestOpenCombineTests.server?.stop()
        super.tearDown()
    }
    
    
    
    override func setUp() {
        func sigHandler(_ signal: Int32) -> Void {
            print("A fatal error has occured")
            #if swift(>=4.1) || _runtime(_ObjC)
            Thread.callStackSymbols.forEach { print($0) }
            #endif
            fflush(stdout)
            exit(1)
        }
        signal(4, sigHandler)
    }
    

    func testSingleRequestPublisher() {
        
        let testURL = self.testURLSearch.appendingQueryItem("q=Swift")
        let session = URLSession.usingWebRequestSharedSessionDelegate()
        defer {
            session.finishTasksAndInvalidate()
        }
        // must retain reference to cancellable otherwise
        // the publisher will get cancelled and no events
        // will be passed along
        //
        // we declare this as an optional so that it can be
        // updated and accessed to make sure no warnings
        // are displayed
        var cancellable: AnyCancellable? = nil
        
        // Test successful request
        if true {
            let sig = DispatchSemaphore(value: 0)
            let request = WebRequest.DataRequest(testURL,
                                                 usingSession: session)
            // must retain reference otherwise
            // publisher's receiveCancel event will get called
            // which will cancel the request
            cancellable = request.publisher().map { (value) -> String in
                return String(data: value.0, encoding: .utf8) ?? "Unable to parse data"
            }
            .replaceError(with: "Error occured")
            .sink { value in
                XCTAssertEqual(value, "Query?q=Swift", "Expected response to match")
                sig.signal()
            }
            if sig.wait(timeout: .now() + 20) == .timedOut {
                XCTFail("Failed to capture")
            }
            
            // test second call to request (after requst finished)
            // this should just end the stored response
            cancellable = request.publisher().map { (value) -> String in
                return String(data: value.0, encoding: .utf8) ?? "Unable to parse data"
            }
            .replaceError(with: "Error occured")
            .sink { value in
                XCTAssertEqual(value, "Query?q=Swift", "Expected response to match")
                sig.signal()
            }
            sig.wait()
        }
        // Test cancelled request
        if true {
            let sig = DispatchSemaphore(value: 0)
            let request = WebRequest.DataRequest(testURL.appendingQueryItem("sleep=3"),
                                                 usingSession: session)
            cancellable = request.publisher().sink(
                receiveCompletion: { r in
                    defer { sig.signal() }
                    switch r {
                        case .finished:
                            XCTFail("Should not have finished")
                        case .failure(let e):
                            XCTAssertEqual(e.errorCode, NSURLErrorCancelled)
                            XCTAssertEqual(e.code, .cancelled)
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should have errored out and not received a value")
                }
            )
            // if we call cancellable
            // then sink/receiveCompletion
            // does not get called so we
            // will call the request.cancel
            // instead to trigger it
            //cancellable?.cancel()
            request.cancel()
            sig.wait()
        }
        
        // We do this to stop the warnings on the cancellable
        // variable indicating that it was written to
        // but not used / accessed
        if let c = cancellable {
            c.cancel()
            cancellable = nil
        }
        
    }
    
    func testDownloadPublisher() {
        let filePath = "\(#file)"
        let fileName = NSString(string: filePath).lastPathComponent
        
        let downloadFileURL = testURLBase
            .appendingPathComponent("/testfiles")
            .appendingPathComponent(fileName)
        
        let session = URLSession.usingWebRequestSharedSessionDelegate()
        defer {
            session.finishTasksAndInvalidate()
        }
        
        let sig = DispatchSemaphore(value: 0)
        let request = WebRequest.DownloadRequest(downloadFileURL,
                                                 usingSession: session)
        // must retain reference to cancellable otherwise
        // the publisher will get cancelled and no events
        // will be passed along
        //
        // we declare this as an optional so that it can be
        // updated and accessed to make sure no warnings
        // are displayed
        var cancellable: AnyCancellable? = request.publisher()
        .sink(
            receiveCompletion: { c in
                if case .failure(let e) = c {
                    XCTFail("Finished with error: \(e)")
                }
                
                sig.signal()
            },
            receiveValue: { r in
                defer {
                    try? FileManager.default.removeItem(at: r.value)
                }
                guard let originalData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                    XCTFail("Failed to load original file '\(filePath)'")
                    return
                }
                guard let downloadData = try? Data(contentsOf: r.value) else {
                    if FileManager.default.fileExists(atPath: r.value.path) {
                        XCTFail("Failed to load downloaded file '\(r.value.path)'")
                    } else {
                        XCTFail("Downloaded file ('\(r.value.path)') is missing and could not be loaded.")
                    }
                    return
                }
                XCTAssertEqual(originalData, downloadData, "Download file does not match orignal file")
            }
        )
        if sig.wait(timeout: .now() + 10) == .timedOut {
            XCTFail("Failed to capture")
        }
        
        // We do this to stop the warnings on the cancellable
        // variable indicating that it was written to
        // but not used / accessed
        if let c = cancellable {
            c.cancel()
            cancellable = nil
        }
    }
    func testUploadPublisher() {
        let filePath = "\(#file)"
        let fileURL = URL(fileURLWithPath: filePath)
        let uploadURL = testURLBase
            .appendingPathComponent("/upload")
        
        let session = URLSession.usingWebRequestSharedSessionDelegate()
        defer {
            session.finishTasksAndInvalidate()
        }
        
        let sig = DispatchSemaphore(value: 0)
        let request = WebRequest.UploadRequest(uploadURL,
                                               fromFile: fileURL,
                                               usingSession: session)
        // must retain reference to cancellable otherwise
        // the publisher will get cancelled and no events
        // will be passed along
        //
        // we declare this as an optional so that it can be
        // updated and accessed to make sure no warnings
        // are displayed
        var cancellable: AnyCancellable? = request.publisher()
        .sink(
            receiveCompletion: { c in
                if case .failure(let e) = c {
                    XCTFail("Finished with error: \(e)")
                }
                sig.signal()
            },
            receiveValue: { r in
                guard let originalData = try? Data(contentsOf: fileURL) else {
                    XCTFail("Unable to load file contents")
                    return
                }
                let fileName = fileURL.lastPathComponent
                guard let uploadedData = self.uploadedData[fileName] ?? self.uploadedData[""] else {
                    XCTFail("Unable to find uploaded data for '\(fileName)'")
                    return
                }
                
                XCTAssertEqual(originalData, uploadedData, "Download file does not match orignal file")
            }
        )
        if sig.wait(timeout: .now() + 10) == .timedOut {
            XCTFail("Failed to capture")
        }
        // We do this to stop the warnings on the cancellable
        // variable indicating that it was written to
        // but not used / accessed
        if let c = cancellable {
            c.cancel()
            cancellable = nil
        }
    }
    
    func testDataEventPublisher() {
        let eventsURL = testURLBase.appendingPathComponent("/events").appendingQueryItem("sleep=0.1")
        
        let session = URLSession.usingWebRequestSharedSessionDelegate()
        defer { session.finishTasksAndInvalidate() }
        
        let eventRequest = URLRequest(url: eventsURL,
                                      cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                      timeoutInterval: .infinity)
        
        let sig = DispatchSemaphore(value: 0)
        let request = WebRequest.DataRequest(eventRequest, usingSession: session)
        var hasReceivedDataEvent: Bool = false
        
        // must retain reference to cancellable otherwise
        // the publisher will get cancelled and no events
        // will be passed along
        //
        // we declare this as an optional so that it can be
        // updated and accessed to make sure no warnings
        // are displayed
        var cancellable: AnyCancellable? = request.dataEventPublisher()
        .sink(
            receiveCompletion: { c in
                defer { sig.signal() }
                if case .failure(let e) = c {
                    XCTFail("Finished with error: \(e)")
                }
                print("Stream Ended")
            },
            receiveValue: { d, r in
                print("Received: \(d)")
                hasReceivedDataEvent = true
            }
        )
        DispatchQueue.global().asyncAfter(deadline: .now() + 20) {
            print("Cancelling request")
            request.cancel()
        }
        if sig.wait(timeout: .now() + 25) == .timedOut {
            XCTFail("Failed wait timeout")
        }
        XCTAssertTrue(hasReceivedDataEvent, "Did not receive any data events")
        // We do this to stop the warnings on the cancellable
        // variable indicating that it was written to
        // but not used / accessed
        if let c = cancellable {
            c.cancel()
            cancellable = nil
        }
    }


    static var allTests = [
        ("testSingleRequestPublisher", testSingleRequestPublisher),
        ("testDownloadPublisher", testDownloadPublisher),
        ("testUploadPublisher", testUploadPublisher),
        ("testDataEventPublisher", testDataEventPublisher)
    ]
}
