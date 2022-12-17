# Web Request Open Combine

![swift >= 5.0](https://img.shields.io/badge/swift-%3E%3D5.0-brightgreen.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat)](LICENSE.md)

Provides cross platform Publisher methods, using OpenCombine, to the WebRequest classes 

## Requirements

* Swift 5.0+
* OpenSwift

## Usage

Data Web Request
```Swift

let session: URLSession = ....

// From The Web Request itself
let request = WebRequest.DataRequest(URL(string: "http://.....")!, usingSession: session)
let cancellable = request.publisher().sink(
    receiveCompletion: { c in
        switch c in {
            case .finished:
                // finished successfully
            case .failure(let e):
                // finished with error
        }
    },
    receiveValue: { r in 
        // The Data Received
        let dta = r.value
        // The URL Response
        let response = r.response
    }
)

// From the URL Session directly
let cancellable = session.webRequestDataTaskPublisher(for: URL(string: "http://.....")!)
    .sink(
        receiveCompletion: { c in
            switch c in {
                case .finished:
                    // finished successfully
                case .failure(let e):
                    // finished with error
            }
        },
        receiveValue: { r in 
            // The Data Received
            let dta = r.value
            // The URL Response
            let response = r.response
        }
    )
```

Data Event Web Request
```Swift

let session: URLSession = ....

// From The Web Request itself
let request = WebRequest.DataRequest(URL(string: "http://.....")!, usingSession: session)
let cancellable = request.dataEventPublisher().sink(
    receiveCompletion: { c in
        switch c in {
            // Note: Cancelling the request and/or publisher
            // will not produce an error here, it will
            // just return finished
            case .finished:
                // finished successfully
            case .failure(let e):
                // finished with error
        }
    },
    receiveValue: { r in 
        // The Data Received
        let dta = r.value
        // The URL Response
        let response = r.response
    }
)

// From the URL Session directly
let cancellable = session.webRequestDataEventTaskPublisher(for: URL(string: "http://.....")!)
    .sink(
        receiveCompletion: { c in
            switch c in {
                case .finished:
                    // finished successfully
                case .failure(let e):
                    // finished with error
            }
        },
        receiveValue: { r in 
            // The Data Received
            let dta = r.value
            // The URL Response
            let response = r.response
        }
    )
```

Download Web Request
```Swift

let session: URLSession = ....

// From The Web Request itself
let request = WebRequest.DownloadRequest(URL(string: "http://.....")!, usingSession: session)
let cancellable = request.publisher().sink(
    receiveCompletion: { c in
        switch c in {
            case .finished:
                // finished successfully
            case .failure(let e):
                // finished with error
        }
    },
    receiveValue: { r in 
        // The URL to the location the file was downloaded to
        let url = r.value
        // The URL Response
        let response = r.response
    }
)

// From the URL Session directly
let cancellable = session.webRequestDownloadTaskPublisher(for: URL(string: "http://.....")!)
    .sink(
        receiveCompletion: { c in
            switch c in {
                case .finished:
                    // finished successfully
                case .failure(let e):
                    // finished with error
            }
        },
        receiveValue: { r in 
            // The URL to the location the file was downloaded to
            let url = r.value
            // The URL Response
            let response = r.response
        }
    )
```

Upload Web Request
```Swift

let session: URLSession = ....

// From The Web Request itself
let request = WebRequest.UploadRequest(URL(string: "http://.....")!, 
                                       fromFile: URL(....), 
                                       usingSession: session)
let cancellable = request.publisher().sink(
    receiveCompletion: { c in
        switch c in {
            case .finished:
                // finished successfully
            case .failure(let e):
                // finished with error
        }
    },
    receiveValue: { r in 
        // The data response from the upload
        let url = r.value
        // The URL Response
        let response = r.response
    }
)

// From the URL Session directly
let cancellable = session.webRequestUploadTaskPublisher(for: URL(string: "http://.....")!,
                                                        fromFile: URL(...))
    .sink(
        receiveCompletion: { c in
            switch c in {
                case .finished:
                    // finished successfully
                case .failure(let e):
                    // finished with error
            }
        },
        receiveValue: { r in 
            // The data response from the upload
            let url = r.value
            // The URL Response
            let response = r.response
        }
    )
```

## Dependencies

* [WebRequest](https://github.com/TheAngryDarling/SwiftWebRequest.git) - The core WebRequest package this package extends to provide Publisher features
* [OpenCombine](https://github.com/OpenCombine/OpenCombine.git) - The 3rd party package that is a replacement for Swift Combine to make this package cross platform compatible
* [LittleWebServer](https://github.com/TheAngryDarling/SwiftLittleWebServer.git) - Used in the **Test Cases** as a local server to test request cases and generate testable responses

## Author

* **Tyler Anger** - *Initial work* 

## License

*Copyright 2022 Tyler Anger*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[HERE](LICENSE.md) or [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
