//
//  ViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ViewController: UIViewController,UITextFieldDelegate {
    
    let settings = UserDefaults.standard
    
    var gotPointArray = Array<(item:String, pt:Int)>()
    var usedPointArray = Array<(item:String, pt:Int)>()
    
    var attrText = NSMutableAttributedString()
    
    var buffArray: [(buffName: String, magnification: Float, category: String, date: Date)] = Array<(String, Float, String, Date)>()
    
    //MARK: - ライフサイクル
    
    // 起動時処理
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //レイアウト読み込み
        pointLabel.layer.borderWidth = 2.0
        pointLabel.layer.borderColor = UIColor.black.cgColor
        buffLog.layer.borderWidth = 1.0
        buffLog.layer.borderColor = UIColor.black.cgColor
        debugLog.layer.borderWidth = 1.0
        debugLog.layer.borderColor = UIColor.black.cgColor
        
        //残pt読み込み
        pointLabel.text = String(roadPoints())
        
        let now = Date()
        var dateBorder: Date
        
        // dateBorderの取得、nilなら明日4時に設定
        if let savedDateBorder: Date = settings.object(forKey: "DateBorder") as! Date? {
//            print(savedDateBorder)
            dateBorder = savedDateBorder
        } else {
            dateBorder = reloadDateBorder()
        }
        
        // バフログ: userDefaultsから取得
        if let dicList = settings.object(forKey: "buffData") as? [[String : Any]] {
            self.buffArray = dicList.map{(buffName: $0["name"] as! String, magnification: $0["mag"] as! Float, category: $0["category"] as! String, date: $0["date"] as! Date)}
            print("消去前: \(buffArray)")
        }
        
        // 期限超過のバフ消去
        for buffIndex in (0..<self.buffArray.count).reversed() {
            if buffArray[buffIndex].date < dateBorder {
                buffArray.remove(at: buffIndex)
                print("消去後: \(buffArray)")
            }
        }
        
        // 日付変更線に関する処理
        if now > dateBorder {
            // テキストログ初期化
            self.attrText = NSMutableAttributedString(string: "日付が更新されました。\n[\(catchTime())] 現在: \(String(roadPoints()))pts\n")
            debugLog.attributedText = attrText
            
            // 日付変更線更新
            dateBorder = reloadDateBorder()
            
        } else {
            // テキストログ取得
            if let archivedLog = settings.object(forKey: "DebugLog") {
                let unarchivedText = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedLog as! Data) as! NSAttributedString
                self.attrText = unarchivedText.mutableCopy() as! NSMutableAttributedString
                debugLog.attributedText = attrText
            // テキストログ取得失敗時
            } else {
                self.attrText = NSMutableAttributedString(string: "読み込みに失敗しました。\n[\(catchTime())] 現在: \(String(roadPoints()))pts\n")
                debugLog.attributedText = attrText
            }
        }
        
        //バフログ書き込み
        writeBuffLog()
        
        // 日付変更線更新
        settings.set(dateBorder, forKey: "DateBorder")
    }
    
    func reloadDateBorder() -> Date {
        let now = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
        let year: Int = Int(dateFormatter.string(from: now))!
        
        dateFormatter.setLocalizedDateFormatFromTemplate("M")
        let month: Int = Int(dateFormatter.string(from: now))!
        
        dateFormatter.setLocalizedDateFormatFromTemplate("d")
        var day: Int = Int(dateFormatter.string(from: now))!
        
        dateFormatter.setLocalizedDateFormatFromTemplate("H")
        let hour: Int = Int(dateFormatter.string(from: now))!
        
        dateFormatter.setLocalizedDateFormatFromTemplate("m")
        let minute: Int = Int(dateFormatter.string(from: now))!
        
        dateFormatter.setLocalizedDateFormatFromTemplate("s")
        let second: Int = Int(dateFormatter.string(from: now))!
        
        if hour >= 4 && minute >= 0 && second >= 0 {
            day += 1
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let dateBorder = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 4, minute: 0, second: 0))!
        return dateBorder
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //残りptを更新
        pointLabel.text = String(roadPoints())
        
        writeDebugLog()
        
        // テキストログをuserDefaultsに保存
        let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
        settings.set(archivedText, forKey: "DebugLog")
    }
    
    func writeDebugLog(){
        // 交換画面での交換履歴をテキストログに表示
        if gotPointArray.isEmpty != true {
            for i in 0..<gotPointArray.count {
                let gotPtText = NSMutableAttributedString(string: "[\(catchTime())] +\(gotPointArray[i].pt)pt: \(gotPointArray[i].item)\n")
                gotPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSMakeRange(0, gotPtText.length))
                self.attrText.insert(gotPtText, at: attrText.length)
            }
            gotPointArray.removeAll()
            self.attrText.insert(NSMutableAttributedString(string: "[\(catchTime())] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        }
        
        // 購入画面での購入履歴をテキストログに表示
        if usedPointArray.isEmpty != true {
            for i in 0..<usedPointArray.count {
                let consumedPtText = NSMutableAttributedString(string: "[\(catchTime())] -\(usedPointArray[i].pt)pt: \(usedPointArray[i].item)\n")
                consumedPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, consumedPtText.length))
                self.attrText.insert(consumedPtText, at: attrText.length)
            }
            usedPointArray.removeAll()
            self.attrText.insert(NSMutableAttributedString(string: "[\(catchTime())] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        }
    }
    
    func writeBuffLog(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        for buffIndex in 0..<buffArray.count {
            buffLog.text += "[\(dateFormatter.string(from: buffArray[buffIndex].date))] \"\(buffArray[buffIndex].buffName)\"が<\(buffArray[buffIndex].category)>で発動中(x\(buffArray[buffIndex].magnification))\n"
        }
    }

    //MARK: - StoryBoard
    
    @IBOutlet weak var pointLabel: UITextField!
    @IBOutlet weak var debugLog: UITextView!
    @IBOutlet weak var buffLog: UITextView!
    
    @IBAction func whenPointLabelEdited(_ sender: UITextField) {
        if pointLabel.text?.isEmpty != true {
            settings.set(pointLabel.text!, forKey: "storePoints")
            self.attrText.insert(NSMutableAttributedString(string: "[\(catchTime())] 現在: \(pointLabel.text!)pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        } else {
            pointLabel.text = String(roadPoints())
        }
    }
    @IBAction func clearButtonTapped(_ sender: Any) {
        settings.removeObject(forKey: "buffData")
        buffArray = Array<(String, Float, String, Date)>()
        buffLog.text.removeAll()
    }
    
    //MARK: - func
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

    // 現在時刻を取得
    func catchTime() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HHmm", options: 0, locale: Locale(identifier: "ja_JP"))
        let time = dateFormatter.string(from: date)
        return time
    }
}

