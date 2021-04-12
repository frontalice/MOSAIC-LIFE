//
//  ViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//
// いぇーい見てる－？

import UIKit

class ViewController: UIViewController,UITextFieldDelegate {
    
    let settings = UserDefaults.standard
    var gotPointArray = Array<Int>()
    var usedPointArray = Array<Int>()

    // 起動時処理
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //レイアウト読み込み
        pointLabel.layer.borderWidth = 2.0
        pointLabel.layer.borderColor = UIColor.black.cgColor
        debugLog.layer.borderWidth = 1.0
        debugLog.layer.borderColor = UIColor.black.cgColor
        
        //残pt・チケット読み込み
        pointLabel.text = String(roadPoints())
        ticketLabel.text = String(roadTickets())
        
        //テスト用：起動毎に初期化
//        settings.removeObject(forKey: "storePoints")
//        settings.removeObject(forKey: "storeTickets")
        
//        settings.register(defaults: ["storePoints":0, "storeTickets":0])
        // テスト中なのでポイントは起動毎に初期化します
//        pointLabel.text = String(roadPoints())
//        ticketLabel.text = String(roadTickets())
        
//        writeFirstLog()
        
        pointDebug.text = "0"
    }
    
//    func writeFirstLog() {
//        var ptString: String? = pointLabel.text
//        ptString = settings.string(forKey: "storePoints")
//        let logText = (t1: "現在: ", t2: "pts\n")
//        if let ptxt = ptString {
//            debugLog.text = logText.0 + ptxt + logText.1
//            return
//        }
//        debugLog.text = "読み込みに失敗しました\n"
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        pointLabel.text = String(roadPoints())
        
        for element1 in gotPointArray {
            debugLog.text += "\(element1)pt獲得しました。\n"
        }
        gotPointArray.removeAll()
        
        for element2 in usedPointArray {
            debugLog.text += "\(element2)pt消費しました。\n"
        }
        usedPointArray.removeAll()
        
        debugLog.text += "現在: \(String(roadPoints()))pts\n"
    }

    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var ticketLabel: UILabel!
    @IBOutlet weak var pointDebug: UITextField!
    @IBOutlet weak var debugLog: UITextView!
    
    func roadPoints() -> Int {
        if settings.object(forKey: "storePoints") != nil {
            let roadPoint : Int = settings.integer(forKey: "storePoints")
            return roadPoint
        }
        settings.set(0, forKey: "storePoints")
        let roadPoint : Int = settings.integer(forKey: "storePoints")
        return roadPoint
    }
    
    func roadTickets() -> Int {
        if settings.object(forKey: "storeTickets") != nil {
            let roadTicket : Int =
                settings.integer(forKey: "storeTickets")
            return roadTicket
        }
        settings.set(0, forKey: "storeTickets")
        let roadTicket : Int =
            settings.integer(forKey: "storeTickets")
        return roadTicket
    }
    
    // デバッグフィールド入力完了時の処理
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.endEditing(true)
        let s = pointDebug.text
        if let newPoint = s {
            settings.set(newPoint, forKey: "storePoints")
        }
        pointLabel.text = s
        return true
    }
    
//    @IBAction func leftButton(_ sender: Any) {
//        performSegue(withIdentifier: "goShop", sender: nil)
//    }
//    @IBAction func rightButton(_ sender: Any) {
//        performSegue(withIdentifier: "goMission", sender: nil)
//    }
}

