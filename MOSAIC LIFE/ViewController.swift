//
//  ViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ViewController: UIViewController,UITextFieldDelegate, UITextViewDelegate {
    
    let settings = UserDefaults.standard
    
    var gotPointArray = Array<(item:String, pt:Int)>()
    var usedPointArray = Array<(item:String, pt:Int)>()
    var ptPerHourArray = Array<Int>()
    
    var attrText = NSMutableAttributedString()
    
    var buffArray: [(buffName: String, magnification: String, category: String, date: Date)] = Array<(String, String, String, Date)>()
    
    var pptMultiplier = 1.05
    
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
        
        self.debugLog.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let now = Date()
        let format = DateFormatter()
        var dateBorder: Date
        
        settings.register(defaults: ["poolingPoint" : 0, "pptMultiplier" : 1.05])
        pptMultiplier = settings.double(forKey: "pptMultiplier")
        pptMultiplierLabel.text = String(pptMultiplier)
        
        // dateBorderの取得、nilなら明日4時に設定
        if let savedDateBorder: Date = settings.object(forKey: "DateBorder") as! Date? {
//            print(savedDateBorder)
            dateBorder = savedDateBorder
        } else {
            dateBorder = reloadDateBorder()
        }
        
        // テスト用
//        settings.removeObject(forKey: "buffData")
        
        // バフログ: userDefaultsから取得
        if let dicList = settings.object(forKey: "buffData") as? [[String : Any]] {
            self.buffArray = dicList.map{(buffName: $0["name"] as! String, magnification: $0["mag"] as! String, category: $0["category"] as! String, date: $0["date"] as! Date)}
        }
        
        // 期限超過のバフ消去
        for buffIndex in (0..<self.buffArray.count).reversed() {
            if buffArray[buffIndex].date < now {
                buffArray.remove(at: buffIndex)
                print("消去後: \(buffArray)")
            }
        }
        
        // テスト用
        // dateBorder = Date(timeInterval: -60*60*24, since: dateBorder)
        
        // 日付変更線に関する処理
        if now > dateBorder {
            // 日付変更線更新
            dateBorder = reloadDateBorder()
            
            // dateBorderを日本時間で取得
            format.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMdHm", options: 0, locale: Locale(identifier: "ja_JP"))
            
            // プールpt処理
//            if settings.integer(forKey: "storePoints") >= 1000 {
//                let pt = settings.integer(forKey: "storePoints") // 前日の獲得pt
//                let ppt = pt - 1000 // ppt移行分
//                settings.set(pt - ppt, forKey: "storePoints")
//                let pptYesterday = settings.integer(forKey: "poolingPoint")
//                var pptToday = Int(Double(ppt + pptYesterday) * pptMultiplier)
//                if pptToday > 100000 { pptToday = 100000 }
//                settings.set(pptToday, forKey: "poolingPoint")
//                self.attrText.insert(NSMutableAttributedString(string: "ppt変換: (\(pptYesterday) + \(ppt)) * \(self.pptMultiplier) → \(pptToday)pts\n"), at: attrText.length)
//            } else {
//                let pptYesterday = settings.integer(forKey: "poolingPoint")
//                var pptToday = Int(Double(pptYesterday) * pptMultiplier)
//                if pptToday > 100000 { pptToday = 100000 }
//                settings.set(pptToday, forKey: "poolingPoint")
//                self.attrText.insert(NSMutableAttributedString(string: "ppt変換: \(pptYesterday) * \(self.pptMultiplier) → \(pptToday)pts\n"), at: attrText.length)
//            }
            
            // プールpt処理（1000pt以下対応版）
            let pt = settings.integer(forKey: "storePoints") // 前日の獲得pt
            var ppt = pt - 1000
            if ppt <= 0 { ppt = 0 }
            settings.set(pt - ppt, forKey: "storePoints")
            let pptYesterday = settings.integer(forKey: "poolingPoint")
            var pptToday = Int(Double(ppt + pptYesterday) * pptMultiplier)
            if pptToday > 100000 { pptToday = 100000 }
            settings.set(pptToday, forKey: "poolingPoint")
            self.attrText.insert(NSMutableAttributedString(string: "ppt変換: (\(pptYesterday) + \(ppt)) * \(self.pptMultiplier) → \(pptToday)pts\n"), at: attrText.length)
            
            
            // テキストログ初期化
            self.attrText.insert(NSMutableAttributedString(string:
                "日付が更新されました。\n" +
                "[\(catchTime())] 現在: \(String(roadPoints()))pts\n" +
                "----------------------------------------------------\n")
            , at:attrText.length)
            
            // 初期化したテキストログを保存
            debugLog.attributedText = attrText
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
            
            // pphArray初期化
            ptPerHourArray.removeAll()
            settings.set(ptPerHourArray, forKey: "ptPerHourArray")
                
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

        //残pt読み込み
        pointLabel.text = String(roadPoints())
        poolingPointLabel.text = "\(String(settings.integer(forKey: "poolingPoint"))) pts POOLing"
        
        //バフログ書き込み
        writeBuffLog()
        
        // 日付変更線更新
        settings.set(dateBorder, forKey: "DateBorder")
        
        // BuffData更新
        let convertedList: [[String: Any]] = buffArray.map{["name": $0.buffName, "mag": $0.magnification, "category": $0.category, "date": $0.date]}
        UserDefaults.standard.set(convertedList, forKey: "buffData")
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
        
//        dateFormatter.setLocalizedDateFormatFromTemplate("m")
//        let minute: Int = Int(dateFormatter.string(from: now))!
//
//        dateFormatter.setLocalizedDateFormatFromTemplate("s")
//        let second: Int = Int(dateFormatter.string(from: now))!
        
        if hour >= 4 {
            day += 1
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let dateBorder = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 4, minute: 0, second: 0))!
        return dateBorder
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        navigationController?.navigationBar.barTintColor = UIColor.secondarySystemBackground
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //残りptを更新
        pointLabel.text = String(roadPoints())
        poolingPointLabel.text = "\(String(settings.integer(forKey: "poolingPoint"))) pts POOLing"
        
//        writeDebugLog()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func writeDebugLog(){
        let timeString = catchTime()
        
        let presentTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "H"
        let ptHour = formatter.string(from: presentTime)
        var presentHour = Int(ptHour)!
        if presentHour <= 3 {
            switch presentHour {
            case 0:
                presentHour = 24
            case 1:
                presentHour = 25
            case 2:
                presentHour = 26
            case 3:
                presentHour = 27
            default:
                break
            }
        }
        print("presentHour: \(presentHour)")
        
        var lastHour: Int!
        if settings.object(forKey: "timeForDivideLine") != nil {
            lastHour = settings.integer(forKey: "timeForDivideLine")
        } else {
            lastHour = presentHour
        }
        
        print("memoryHour: \(lastHour!)")
        if lastHour <= 3 {
            switch lastHour {
            case 0:
                lastHour = 24
            case 1:
                lastHour = 25
            case 2:
                lastHour = 26
            case 3:
                lastHour = 27
            default:
                break
            }
        }
        print("lastHour: \(lastHour!)\n-------------------")
        
        if let savedPphArray = settings.array(forKey: "ptPerHourArray") as? [Int] {
            ptPerHourArray = savedPphArray
        }
        
        // 交換画面での交換履歴をテキストログに表示
        if gotPointArray.isEmpty != true {
            if presentHour > lastHour {
                let lastPt = ptPerHourArray[ptPerHourArray.count - 1]
                ptPerHourArray.removeLast()
                let hourSum = ptPerHourArray.reduce(0, {$0+$1})
                ptPerHourArray.removeAll()
                self.attrText.insert(NSAttributedString(string: "---------↑\(lastHour!)-\(presentHour)時合計: \(hourSum)pt---------\n"), at: attrText.length)
                ptPerHourArray.append(lastPt)
                settings.set(ptPerHourArray, forKey: "ptPerHourArray")
            }
            for i in 0..<gotPointArray.count {
                let gotPtText = NSMutableAttributedString(string: "[\(timeString)] +\(gotPointArray[i].pt)pt: \(gotPointArray[i].item)\n")
                gotPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSMakeRange(0, gotPtText.length))
                self.attrText.insert(gotPtText, at: attrText.length)
            }
            gotPointArray.removeAll()
            self.attrText.insert(NSMutableAttributedString(string: "[\(timeString)] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        }
        
        // 購入画面での購入履歴をテキストログに表示
        if usedPointArray.isEmpty != true {
            if presentHour > lastHour {
                let lastPt = ptPerHourArray[ptPerHourArray.count - 1]
                ptPerHourArray.removeLast()
                let hourSum = ptPerHourArray.reduce(0, {$0+$1})
                ptPerHourArray.removeAll()
                self.attrText.insert(NSAttributedString(string: "---------↑\(lastHour!)-\(presentHour)時合計: \(hourSum)pt---------\n"), at: attrText.length)
                ptPerHourArray.append(lastPt)
                settings.set(ptPerHourArray, forKey: "ptPerHourArray")
            }
            for i in 0..<usedPointArray.count {
                let consumedPtText = NSMutableAttributedString(string: "[\(timeString)] -\(usedPointArray[i].pt)pt: \(usedPointArray[i].item)\n")
                consumedPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, consumedPtText.length))
                self.attrText.insert(consumedPtText, at: attrText.length)
            }
            usedPointArray.removeAll()
            self.attrText.insert(NSMutableAttributedString(string: "[\(timeString)] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        }
        
//        print("\(debugLog.attributedText!)\n------------------------------------")
        
        settings.set(presentHour, forKey: "timeForDivideLine")
        
        // テキストログをuserDefaultsに保存
        let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
        settings.set(archivedText, forKey: "DebugLog")
    }
    
    func writeBuffLog(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "M/d H:mm", options: 0, locale: Locale(identifier: "ja_JP"))
        for buffIndex in 0..<buffArray.count {
            buffLog.text += "[\(dateFormatter.string(from: buffArray[buffIndex].date))] \"\(buffArray[buffIndex].buffName)\"が<\(buffArray[buffIndex].category)>で発動中(x\(buffArray[buffIndex].magnification))\n"
        }
    }

    //MARK: - StoryBoard
    
    @IBOutlet weak var pointLabel: UITextField!
    @IBOutlet weak var poolingPointLabel: UILabel!
    @IBOutlet weak var debugLog: UITextView!
    @IBOutlet weak var buffLog: UITextView!
    @IBOutlet weak var pptMultiplierLabel: UITextField!
    
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
        let alert : UIAlertController = UIAlertController(title: nil, message: "初期化してもいい？", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction!) -> Void in
            self.settings.removeObject(forKey: "buffData")
            self.buffArray = Array<(String, String, String, Date)>()
            self.buffLog.text.removeAll()
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func whenPptMultiplierLabelEdited(_ sender: Any) {
        if let text = pptMultiplierLabel.text {
            pptMultiplier = Double(text)!
            settings.set(Double(text), forKey: "pptMultiplier")
        }
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
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if debugLog.isFirstResponder {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                } else {
                    let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                    self.view.frame.origin.y -= suggestionHeight
                }
            }
        }
    }
        
    @objc func keyboardWillHide() {
        if debugLog.isFirstResponder {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    }
}

extension ViewController {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == debugLog {
            attrText = debugLog.attributedText!.mutableCopy() as! NSMutableAttributedString
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
        }
    }
    
}
