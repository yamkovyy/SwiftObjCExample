//
//  CMServerIOUtils.swift
//  ConnectMeditation
//
//  Created by viera on 3/9/16.
//  Copyright © 2016 ScopicSoftware. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Accounts
import Social
import FBSDKLoginKit

private var _alamofireManagerInstance: Manager! = nil

class CMServerIOUtils
{
    enum ErrorCode: Int
    {
        case Cancelled = -10000
        case General = 10000
        case SignUpFail
        case LogInFail
        case FacebookUserDataMissing
        case DeviceTokenMissing
        
        func getError(message: String? = nil) -> NSError
        {
            var msg: String? = nil
            if let m = message
            {
                msg = m
            }
            else // use default
            {
                switch self
                {
                case Cancelled: msg = "Cancelled"
                case General: msg = "Failed to process"
                case SignUpFail: msg = "Failed to sign up"
                case LogInFail: msg = "Failed to sign in"
                case FacebookUserDataMissing: msg = "User data missing"
                case DeviceTokenMissing: msg = "Device token missing"
                }
            }
            return CMServerIOUtils.error(message: msg, code: self.rawValue)
        }
    }
    
    class func error(message message: String? = nil, info: [String : AnyObject]? = nil, code: Int = ErrorCode.General.rawValue) -> NSError
    {
        var userInfo: [String : AnyObject] = info ?? [:]
        if let m = message
        {
            userInfo[NSLocalizedDescriptionKey] = m
        }
        return NSError(domain: "CMNetworkUtils", code: code, userInfo: userInfo)
    }
    
    class func dataFromResponce(response: Alamofire.Response<AnyObject, NSError>, code: Int = ErrorCode.General.rawValue) -> (JSON? , NSError?)
    {
        var d: JSON? = nil
        var e: NSError? = nil
        
        debugPrint(response)
        print(NSString(data: response.data!, encoding: NSUTF8StringEncoding))
        
        switch response.result
        {
        case .Success(let data):
            let json = JSON(data)
            if let status = json["status"].int
            {
                if status == 1
                {
                    d = json
                }
                else
                {
                    e = CMServerIOUtils.error(message: json["message"].string, code: code)
                }
            }
            if let serverDate = NSDate.fromServerString(json["serverDate"].string)
            {
                CMAppData.saveCurrentTime(serverDate)
            }
            
        case .Failure(let error):
            e = error
        }
        
        return (d, e)
    }
    
    
    class func alamofire() -> Manager
    {
        if _alamofireManagerInstance == nil
        {
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.requestCachePolicy = .ReloadIgnoringLocalAndRemoteCacheData
            //            config.timeoutIntervalForRequest = 10
            //            config.timeoutIntervalForResource = 10
            _alamofireManagerInstance = Manager(configuration: config)
        }
        
        return _alamofireManagerInstance
    }
}

extension Alamofire.Manager
{
    func URLRequest(
        method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        headers: [String: String]? = nil)
        -> NSMutableURLRequest
    {
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URLString.URLString)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let headers = headers {
            for (headerField, headerValue) in headers {
                mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        
        return mutableURLRequest
    }
    
    public func requestTimed(
        method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding = .URL,
        headers: [String: String]? = nil,
        timeoutInterval: NSTimeInterval = 15)
        -> Request
    {
        let mutableURLRequest = URLRequest(method, URLString, headers: headers)
        mutableURLRequest.timeoutInterval = timeoutInterval
        let encodedURLRequest = encoding.encode(mutableURLRequest, parameters: parameters).0
        return Alamofire.request(encodedURLRequest)
    }
    
    public func downloadTimed(
        method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding = .URL,
        headers: [String: String]? = nil,
        timeoutInterval: NSTimeInterval = 3600,
        destination: Request.DownloadFileDestination)
        -> Request
    {
        let mutableURLRequest = URLRequest(method, URLString, headers: headers)
        mutableURLRequest.timeoutInterval = timeoutInterval
        let encodedURLRequest = encoding.encode(mutableURLRequest, parameters: parameters).0
        
        return download(encodedURLRequest, destination: destination)
    }
}

extension NSDate
{
    func toSettingsString(addTime: Bool = true) -> String?
    {
        var res: String? = nil
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        
        let formatter = NSDateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = addTime ? "MM/dd/yyyy HH:mm:ss" : "MM/dd/yyyy"
        res = formatter.stringFromDate(self)
        
        return res
    }
    
    func toServerString() -> String?
    {
        var res: String? = nil
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        
        let formatter = NSDateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        res = formatter.stringFromDate(self)
        
        return res
    }
    
    class func fromServerString(string: String?) -> NSDate?
    {
        var res: NSDate? = nil
        if let s = string
        {
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            
            let formatter = NSDateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            res = formatter.dateFromString(s)
        }
        return res
    }
    
    func modifyDate(days days: Int = 0, months: Int = 0, years: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) -> NSDate?
    {
        let shiftComps = NSDateComponents()
        shiftComps.year = years
        shiftComps.month = months
        shiftComps.day = days
        shiftComps.hour = hours
        shiftComps.minute = minutes
        shiftComps.second = seconds
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        calendar?.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        
        return calendar?.dateByAddingComponents(shiftComps, toDate: self, options: [])
    }
    
    class func isDateValid(startDate startDate: NSDate? = nil, endDate: NSDate? = nil) -> Bool
    {
        return NSDate().isDateValid(startDate: startDate, endDate: endDate)
    }
    
    func isDateValid(startDate startDate: NSDate? = nil, endDate: NSDate? = nil) -> Bool
    {
        var res = true
        
        if let sd = startDate
        {
            res = self.compare(sd) != NSComparisonResult.OrderedAscending
        }
        
        if res == true
        {
            if let ed = endDate
            {
                res = self.compare(ed) != NSComparisonResult.OrderedDescending
            }
        }
        
        return res
    }
}
