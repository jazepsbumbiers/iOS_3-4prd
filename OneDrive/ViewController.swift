//
//  ViewController.swift
//
//  Created by Jazeps on 06/03/2018.
//  Copyright © 2018 Jazeps. All rights reserved.
//
import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var filetable: UITableView!
    @IBOutlet weak var fileCell: UITableViewCell!
    
    var fileNames = [] as Array
    var fileLinks = [] as Array
    
    var code = ""
    let client_id = "a74d3beb-bc2a-4ba5-b650-fda92574023a"
    let scope = "files.read"
    let redirect_uri = "msala74d3beb-bc2a-4ba5-b650-fda92574023a://auth"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let driveLink = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=\(client_id)&scope=\(scope)&response_type=code&redirect_uri=\(redirect_uri)"
        
        let odURL = URL(string: driveLink)
        let openOdPageRequest = URLRequest(url: odURL!)
        webView.navigationDelegate = self as WKNavigationDelegate;
        webView.load(openOdPageRequest)
        
        
        filetable.delegate = self as! UITableViewDelegate
        filetable.dataSource = self as! UITableViewDataSource
        
    }
    
    func numberOfSectionsInTableView(filetable: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ filetable: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    func tableView(_ filetable: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileURL = fileLinks[indexPath.row] as? String
        print(fileNames[indexPath.row])
        
        let filePath = Bundle.main.path(forResource: fileURL, ofType: "jpg")
        
        let folderPath = Bundle.main.path(forAuxiliaryExecutable: "folder")
        
        let fileUrl = NSURL(fileURLWithPath: filePath!)
        let baseUrl = NSURL(fileURLWithPath: folderPath!, isDirectory: true)
        
        webView.loadFileURL(fileUrl as URL, allowingReadAccessTo: baseUrl as URL)

        
    }
    
    
    
    func tableView(_ filetable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell:UITableViewCell = UITableViewCell(style:UITableViewCellStyle.default, reuseIdentifier:"Cell")
        
        cell.textLabel!.text = fileNames[indexPath.row] as? String
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)
    {
        
        let string = navigationAction.request.url?.absoluteString
        var string_arr = string?.components(separatedBy: "=")
        
        if ( string_arr![0].range(of:"code") != nil ) {
            code = string_arr![1]
            var access_token = ""
            
            let url = URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token")!
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let postString = "client_id=\(client_id)&redirect_uri=\(redirect_uri)&code=\(code)&grant_type=authorization_code"
            request.httpBody = postString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(error)")
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(response)")
                }
                
                let responseString = String(data: data, encoding: String.Encoding.utf8)
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    access_token = json["access_token"] as! String
                    var get_json = self.getDrive(url: "https://graph.microsoft.com/v1.0/me/drives/51420aa3cd61f800/root/children", access_token: access_token, forHTTPHeaderField: "Authorization", httpMethod: "GET")

                }
                catch let error as NSError {
                    print(error)
                }

            }
            task.resume()
        }
  
        decisionHandler(.allow)
    }
    
    func downloadFile(url: String) {
        
        if let audioUrl = URL(string: url) {
            
            // then lets create your document folder url
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // lets create your destination file url
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(audioUrl.lastPathComponent)
            self.fileLinks.append(destinationUrl)
            print(destinationUrl)
            
            // to check if it exists before downloading it
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("The file already exists at path")
                
                // if the file doesn't exist
            } else {
                
                // you can use NSURLSession.sharedSession to download the data asynchronously
                URLSession.shared.downloadTask(with: audioUrl, completionHandler: { (location, response, error) -> Void in
                    guard let location = location, error == nil else { return }
                    do {
                        // after downloading your file you need to move it to your destination url
                        try FileManager.default.moveItem(at: location, to: destinationUrl)
                        print("File moved to documents folder")
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }).resume()
            }
        }
        
    }
    
    
    func getDrive(url: String, access_token: String, forHTTPHeaderField: String, httpMethod: String) ->Swift.Void {
        
        let get_url = URL(string: url)!
        var request = URLRequest(url: get_url)
        request.setValue("Bearer \(access_token)", forHTTPHeaderField: forHTTPHeaderField)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: String.Encoding.utf8)
            do {
                DispatchQueue.main.async {
                    //self.webView .removeFromSuperview()
                    self.webView.isHidden = true
                    self.filetable.isHidden = false
                    //access_token = json["access_token"] as! String
                }
            }
            catch let error as NSError {
                print(error)
            }
            //print("responseString = \(responseString!)")
            
            let jsonText = responseString
            var dictonary:NSDictionary?
            
            if let data = jsonText?.data(using: String.Encoding.utf8) {
                
                do {
                    dictonary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as! NSDictionary
                    let valueDic = dictonary!["value"] as! NSArray
                    
                    //var fileNames = [] as Array
                    //var fileLinks = [] as Array
                  
                    for myFile in valueDic {
                        let element = myFile as! NSDictionary
                        let myLink = element["@microsoft.graph.downloadUrl"] as! String
                        let myName = element["name"] as! String
                        //self.fileLinks.append(myLink)
                        self.fileNames.append(myName)
                        
                        DispatchQueue.main.async {
                            self.filetable.reloadData()
                            print(myName + " added to tableview")
                        }
                        
                        self.downloadFile(url: myLink)
                        
                    }
                    
                    print(self.fileNames)
                } catch let error as NSError {
                    print(error)
                }
            }
        }
        task.resume()
    }


}

