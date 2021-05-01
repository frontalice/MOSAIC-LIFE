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
    var gotPointArray = Array<(item:String, pt:Int)>()
    var usedPointArray = Array<(item:String, pt:Int)>()

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
//        ticketLabel.text = String(roadTickets())
        
        pointDebug.text = "0"
        
        debugLog.text += "現在: \(String(roadPoints()))pts\n"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pointLabel.text = String(roadPoints())
        
        // 交換画面での交換履歴をテキストログに表示
        if gotPointArray.isEmpty != true {
            for i in 0..<gotPointArray.count {
                debugLog.text += "「\(gotPointArray[i].item)」で\(gotPointArray[i].pt)pt獲得しました。\n"
            }
            gotPointArray.removeAll()
            debugLog.text += "現在: \(String(roadPoints()))pts\n"
        }
        
        // 購入画面での購入履歴をテキストログに表示
        if usedPointArray.isEmpty != true {
            for i in 0..<usedPointArray.count {
                debugLog.text += "「\(usedPointArray[i].item)」で\(usedPointArray[i].pt)pt消費しました。\n"
            }
            usedPointArray.removeAll()
            debugLog.text += "現在: \(String(roadPoints()))pts\n"
        }
    }

    @IBOutlet weak var pointLabel: UILabel!
//    @IBOutlet weak var ticketLabel: UILabel!
    @IBOutlet weak var pointDebug: UITextField!
    @IBOutlet weak var debugLog: UITextView!
    
    // 現在ptを読み込み
    func roadPoints() -> Int {
        if settings.object(forKey: "storePoints") != nil {
            let roadPoint : Int = settings.integer(forKey: "storePoints")
            return roadPoint
        }
        //nilの場合「0pt」で表示
        settings.set(0, forKey: "storePoints")
        let roadPoint : Int = settings.integer(forKey: "storePoints")
        return roadPoint
    }
    
//    func roadTickets() -> Int {
//        if settings.object(forKey: "storeTickets") != nil {
//            let roadTicket : Int =
//                settings.integer(forKey: "storeTickets")
//            return roadTicket
//        }
//        settings.set(0, forKey: "storeTickets")
//        let roadTicket : Int =
//            settings.integer(forKey: "storeTickets")
//        return roadTicket
//    }
    
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

