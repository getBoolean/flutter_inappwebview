//
//  CustomURLProtocol.swift
//  flutter_inappwebview_ios
//
//  Created by Boolean on 1/30/24.
//

import Foundation

class CustomURLProtocol: URLProtocol {
    
    var dataTask: URLSessionDataTask?
    var urlResponse: URLResponse?
    var receivedData: NSMutableData?
    weak var delegate: CustomURLProtocolDelegate?

    // Check if this protocol can handle the given request
    override class func canInit(with request: URLRequest) -> Bool {
        // Avoid handling the same request multiple times
        if URLProtocol.property(forKey: "CustomURLProtocolHandled", in: request) != nil {
            return false
        }
        // Here you can filter the requests you want to intercept
        return true
    }

    // Return a canonical version of the request
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    // Start loading the request
    override func startLoading() {
        guard let newRequest = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
        URLProtocol.setProperty(true, forKey: "CustomURLProtocolHandled", in: newRequest)
        
        // Perform the request using URLSession
        dataTask = URLSession.shared.dataTask(with: newRequest as URLRequest, completionHandler: { [weak self] (data, response, error) in
            if let strongSelf = self {
                if let data = data, let response = response {
                    strongSelf.delegate?.interceptRequest(data, response: response, forRequest: strongSelf.request)
                    strongSelf.receivedData = NSMutableData(data: data)
                    strongSelf.urlResponse = response
                    strongSelf.client?.urlProtocol(strongSelf, didReceive: response, cacheStoragePolicy: .notAllowed)
                    strongSelf.client?.urlProtocol(strongSelf, didLoad: data)
                }
                
                if let error = error {
                    strongSelf.client?.urlProtocol(strongSelf, didFailWithError: error)
                } else {
                    strongSelf.client?.urlProtocolDidFinishLoading(strongSelf)
                }
            }
        })
        dataTask?.resume()
    }

    // Stop loading the request
    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
}

protocol CustomURLProtocolDelegate: AnyObject {
    func interceptRequest(_ data: Data, response: URLResponse, forRequest request: URLRequest);
}
