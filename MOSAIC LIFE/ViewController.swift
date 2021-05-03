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
    var attrText = NSMutableAttributedString()
    let date = Date()
    let dateFormatter = DateFormatter()
    
    // 起動時処理
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //レイアウト読み込み
        pointLabel.layer.borderWidth = 2.0
        pointLabel.layer.borderColor = UIColor.black.cgColor
        debugLog.layer.borderWidth = 1.0
        debugLog.layer.borderColor = UIColor.black.cgColor
        
        //残pt読み込み
        pointLabel.text = String(roadPoints())
        
        //デバッグエリア初期化
        pointDebug.text = "0"
        
        //時刻フォーマット読み込み
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HHmm", options: 0, locale: Locale(identifier: "ja_JP"))
        let time = dateFormatter.string(from: date)
        
        //デバッグログ初期化
        self.attrText = NSMutableAttributedString(string: "[\(time)] 現在: \(String(roadPoints()))pts\n")
        debugLog.attributedText = attrText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pointLabel.text = String(roadPoints())
        
        let time = dateFormatter.string(from: date)
        
        // 交換画面での交換履歴をテキストログに表示
        if gotPointArray.isEmpty != true {
            for i in 0..<gotPointArray.count {
                let gotPtText = NSMutableAttributedString(string: "[\(time)] +\(gotPointArray[i].pt)pt: \"\(gotPointArray[i].item)\"\n")
                gotPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSMakeRange(0, gotPtText.length))
                self.attrText.insert(gotPtText, at: attrText.length)
//                debugLog.text += "「\(gotPointArray[i].item)」で\(gotPointArray[i].pt)pt獲得しました。\n"
            }
            gotPointArray.removeAll()
            self.attrText.insert(NSMutableAttributedString(string: "[\(time)] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
//            debugLog.text += "現在: \(String(roadPoints()))pts\n"
        }
        
        // 購入画面での購入履歴をテキストログに表示
        if usedPointArray.isEmpty != true {
            for i in 0..<usedPointArray.count {
                let consumedPtText = NSMutableAttributedString(string: "[\(time)] -\(usedPointArray[i].pt)pt: \"\(usedPointArray[i].item)\"\n")
                consumedPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, consumedPtText.length))
                self.attrText.insert(consumedPtText, at: attrText.length)
//                debugLog.text += "「\(usedPointArray[i].item)」で\(usedPointArray[i].pt)pt消費しました。\n"
            }
            usedPointArray.removeAll()
            self.attrText.insert(NSMutableAttributedString(string: "[\(time)] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
//            debugLog.text += "現在: \(String(roadPoints()))pts\n"
        }
    }

    @IBOutlet weak var pointLabel: UILabel!
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
}

