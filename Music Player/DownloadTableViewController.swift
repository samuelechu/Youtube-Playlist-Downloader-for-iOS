//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class downloadTableViewController: UITableViewController, downloadTableViewControllerDelegate {
    
    
    var downloadCells: [DownloadCellInfo] = []
     
    var dataDownloader : DataDownloader!
    var downloadTasks : [String] = []
    var uncachedVideos : [String] = []
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        if let appDel = UIApplication.shared.delegate as? AppDelegate {
            appDel.downloadTable = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(downloadTableViewController.hideTabBar))
        view.addGestureRecognizer(tap)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadTableViewController.resetDownloadTasks(_:)), name: NSNotification.Name(rawValue: "resetDownloadTasksID"), object: nil)
        
        tableView.backgroundColor = UIColor.clear
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
    }
    
    func hideTabBar(){
        setTabBarVisible(!(tabBarIsVisible()), animated: true)
        let visible = (navigationController?.isNavigationBarHidden)!
        navigationController?.setNavigationBarHidden(!visible, animated: true)
    }
    
    func setTabBarVisible(_ visible:Bool, animated:Bool) {
        if (tabBarIsVisible() == visible) { return }
        
        // get a frame calculation ready for tabBar
        let frame = self.tabBarController?.tabBar.frame
        let height = (frame?.size.height)!
        let offsetY = (visible ? -height : height)
        
        // zero duration means no animation
        let duration:TimeInterval = (animated ? 0.2 : 0.0)
        
        //  animate the tabBar
        if frame != nil {
            
            UIView.animate(withDuration: duration, animations: {
                self.tabBarController?.tabBar.frame = frame!.offsetBy(dx: 0, dy: offsetY)
                return
            }) 
        }
    }
    
    func tabBarIsVisible() ->Bool {
        return self.tabBarController?.tabBar.frame.origin.y < self.view.frame.maxY
    }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    //func setDLObject(session : DataDownloader){ dataDownloader = session }
    //func getDLObject() -> DataDownloader? { return dataDownloader }
    func addDLTask(_ tasks : [String]){ downloadTasks += tasks }
    func getDLTasks() -> [String] { return downloadTasks }
    func addUncachedVid(_ identifier: [String]) { uncachedVideos += identifier}
    func getUncachedVids() -> [String] { return uncachedVideos }
    
    func resetDownloadTasks(_ notification: Notification){
        let dict : NSDictionary? = notification.userInfo as NSDictionary?
        if dict == nil {
            downloadTasks = []
        }
        
        else {
            let identifier = dict!.value(forKey: "identifier") as! String
            let x = downloadTasks.index(of: identifier)
            if x != nil {
                downloadTasks.remove(at: x!)
            }
            
        }
    }
    
    //update taskProgress of specific cell
    func setProgressValue(_ dict : NSDictionary){
        let cellNum : Int = (dict.value(forKey: "ndx")! as AnyObject).intValue
        
        if cellNum < downloadCells.count {
            let taskProgress : Float = dict.value(forKey: "value") as! Float
            downloadCells[cellNum].setProgress(taskProgress)
            reloadCellAtNdx(cellNum)
        }
    }
    
    func reloadCellAtNdx(_ cellNum : Int){
        if cellNum < downloadCells.count{
            let indexPath = IndexPath(row: cellNum, section: 0)
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
        }
    }
    
    func addCell(_ dict : NSDictionary){
        let newCell = dict.value(forKey: "cellInfo") as! DownloadCellInfo
        downloadCells += [newCell]
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadCells.count
    }
    
    //populate cells with data from downloadCells : [DownloadCellInfo]
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> downloadCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadCell", for: indexPath) as! downloadCell
        
        let cellInfo = downloadCells[indexPath.row]
        
        cell.accessoryType = UITableViewCellAccessoryType.none
        if cellInfo.downloadFinished() { cell.accessoryType = UITableViewCellAccessoryType.checkmark }
        
        cell.progressBar.progress = cellInfo.progress
        cell.imageLabel.image = cellInfo.image
        cell.durationLabel.text = cellInfo.duration
        cell.nameLabel.text = cellInfo.name
        
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear

        return cell
    }
}
