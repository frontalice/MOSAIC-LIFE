//
//  ViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit
typealias NSMAttrStr = NSMutableAttributedString

class ViewController: UIViewController,UITextFieldDelegate, UITextViewDelegate {
    
    let settings = UserDefaults.standard
    
    var gotPointArray = Array<(item:String, pt:Int)>()
    var usedPointArray = Array<(item:String, pt:Int)>()
    var ptPerHourArray = Array<Int>()
    
    var attrText = NSMAttrStr()
    
    var buffArray: [(buffName: String, magnification: String, category: String, date: Date)] = Array<(String, String, String, Date)>()
    
    var pptMultiplier = 1.05
    
    var currentSpt = 0
    var sptRank = 0
    var sptCount = 0
    var sptRankData = [ 0:1.0, 1:1.2, 2:1.5, 3:2.0, 4:3.0, 5:4.0, 6:5.0 ]
    var overCounter = 0
    let effectStrs = [
        ["\u{1F534}", "\u{2B55}", "\u{1F53B}"],
        ["\u{1F4A0}", "\u{1F537}", "\u{1F539}"],
        ["\u{1F49A}", "\u{2733}", "\u{2747}"]
    ]
    var effectsCount = [[0,0,0],[0,0,0],[0,0,0]]
    
    //MARK: - ライフサイクル
    
    // 起動時処理
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        settings.register(defaults: [
            "poolingPoint" : 0,
            "pptMultiplier" : 1.05,
            "spt" : 0,
            "sptRank" : 0,
            "sptCount" : 0,
            "subscPrice" : 0,
            "isDayChanged" : false,
            "migrateCount" : 2,
            "effectsCount" : [[0,0,0],[0,0,0],[0,0,0]]
        ])
        pptMultiplier = settings.double(forKey: "pptMultiplier")
//        pptMultiplierLabel.text = String(pptMultiplier)
        pptMultiplierButton.setTitle(String(pptMultiplier), for: .normal)
        currentSpt = settings.integer(forKey: "spt")
        sptRank = settings.integer(forKey: "sptRank")
        sptCount = settings.integer(forKey: "sptCount")
        
        //レイアウト読み込み
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        ptlabelStack.layer.cornerRadius = 18
        pointLabel.layer.borderWidth = 2.0
        pointLabel.layer.borderColor = UIColor {_ in return #colorLiteral(red: 1, green: 0.4718433711, blue: 0, alpha: 1)}.cgColor
        pointLabel.layer.cornerRadius = 20
        pointLabel.layer.masksToBounds = true
        
        shopButton.layer.cornerRadius = 20
        missionButton.layer.cornerRadius = 20
        
        debugLog.layer.borderWidth = 1.0
        debugLog.layer.borderColor = UIColor.black.cgColor
        
        effectStack.layer.cornerRadius = 5
        
//        self.debugLog.delegate = self -> Storyboardで設定済み
        
        let effectBtns = [angerEffectBtn, exploreEffectBtn, heartEffectBtn]
        effectsCount = (settings.object(forKey: "effectsCount") as? [[Int]])!
        for i in 0 ... 2 {
            effectBtns[i]?.titleLabel?.numberOfLines = 3
            effectBtns[i]?.titleLabel?.textAlignment = .center
            var text = ""
            for j in 0 ..< 2 {
                text += "\(effectStrs[i][j])x \(effectsCount[i][j])\n"
            }
            text += "\(effectStrs[i][2])x \(effectsCount[i][2])"
            effectBtns[i]?.setTitle(text, for: .normal)
        }
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        let now = Date()
        let format = DateFormatter()
        var dateBorder: Date
        
        // dateBorderの取得、nilなら明日4時に設定
        if let savedDateBorder: Date = settings.object(forKey: "DateBorder") as! Date? {
            dateBorder = savedDateBorder
        } else {
            dateBorder = reloadDateBorder()
        }
        
        
        // 日付変更線に関する処理
        if now > dateBorder {
            
            var earlyBorder = Calendar.current.date(byAdding: .hour, value: 2, to: dateBorder)
            earlyBorder = Calendar.current.date(byAdding: .minute, value: 30, to: earlyBorder!)
            
            // 日付変更線更新
            dateBorder = reloadDateBorder()
            
            // dateBorderを日本時間で取得
            format.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMdHm", options: 0, locale: Locale(identifier: "ja_JP"))
            
            // プールpt処理（1000pt以下対応版）
            let pt = settings.integer(forKey: "storePoints") // 前日の獲得pt
            var ppt = pt - 1000
            if ppt <= 0 { ppt = 0 }
            settings.set(pt - ppt, forKey: "storePoints")
            let pptYesterday = settings.integer(forKey: "poolingPoint")
            var pptToday : Int
            if pptYesterday > 10000 {
                if pptMultiplier >= 1.2 {
                    pptToday = Int(Double(ppt + pptYesterday) * 1.03)
                } else if pptMultiplier >= 1.1 {
                    pptToday = Int(Double(ppt + pptYesterday) * 1.02)
                } else if pptMultiplier > 1{
                    pptToday = Int(Double(ppt + pptYesterday) * 1.01)
                } else {
                    pptToday = ppt + pptYesterday
                }
            } else {
                pptToday = Int(Double(ppt + pptYesterday) * pptMultiplier)
            }
            if pptToday > 25000 { pptToday = 25000 }
            settings.set(pptToday, forKey: "poolingPoint")
            self.attrText.insert(NSMAttrStr(
                string: "ppt変換: (\(pptYesterday) + \(ppt)) * \(self.pptMultiplier) → \(pptToday)pts\n"),
                at: attrText.length
            )
            pptMultiplier = 1.05
            pptMultiplierButton.setTitle("1.05", for: .normal)
            settings.set(pptMultiplier, forKey: "pptMultiplier")
            
            if now < earlyBorder! {
                settings.set(3, forKey: "migrateCount")
            } else {
                settings.set(2, forKey: "migrateCount")
            }
            
            // spt関連の処理
            sptCount -= 1
            if sptCount == 0 && sptRank > 0 {
                sptRank -= 1
                sptCount = 2
            }
            resetSpt()
            settings.set(settings.integer(forKey: "spt") + settings.integer(forKey: "subscPrice"), forKey: "spt")
            settings.set(sptCount, forKey: "sptCount")
            currentSpt = settings.integer(forKey: "spt")
            
            // テキストログ初期化
            self.attrText.insert(NSMAttrStr(string:
                "日付が更新されました。\n" +
                "[\(catchTime())] 現在: \(String(roadPoints()))pts\n" +
                "補正レベル: Lv\(sptRank) / 残り\(sptCount)日\n" +
                "----------------------------------------------------\n")
            , at:attrText.length)
            
            // 初期化したテキストログを保存
            debugLog.attributedText = attrText
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
            
            // pphArray初期化
            ptPerHourArray.removeAll()
            settings.set(ptPerHourArray, forKey: "ptPerHourArray")
            
            settings.set(true, forKey: "isDayChanged")
                
        } else {
            // テキストログ取得
            if let archivedLog = settings.object(forKey: "DebugLog") {
                let unarchivedText = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedLog as! Data) as! NSAttributedString
                self.attrText = unarchivedText.mutableCopy() as! NSMAttrStr
                debugLog.attributedText = attrText
            // テキストログ取得失敗時
            } else {
                self.attrText = NSMAttrStr(string: "読み込みに失敗しました。\n[\(catchTime())] 現在: \(String(roadPoints()))pts\n")
                debugLog.attributedText = attrText
            }
        }

        //残pt読み込み
        pointLabel.text = String(roadPoints())
        poolingPointLabel.text = "\(String(settings.integer(forKey: "poolingPoint"))) pts POOLing"
        
        //spt読み込み
        currentSptLabel.text = String(currentSpt)
        addingSptLabel.text = ""
        currencyButton.setTitle("x\(settings.double(forKey: "moneyMultiplier"))", for: .normal)
        
        //バフログ書き込み
//        writeBuffLog()
        
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
        
        if hour >= 4 {
            day += 1
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let dateBorder = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 4, minute: 0, second: 0))!
        return dateBorder
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationBar.barTintColor = UIColor.secondarySystemBackground
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        self.debugLog.scrollRangeToVisible(NSRange(location: self.debugLog.attributedText.length-1, length: 1))
        
        //残りptを更新
        pointLabel.text = String(roadPoints())
        poolingPointLabel.text = "\(String(settings.integer(forKey: "poolingPoint"))) pts POOLing"
        pptMultiplierButton.setTitle(String(settings.double(forKey: "pptMultiplier")), for: .normal)
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
                case 0: presentHour = 24
                case 1: presentHour = 25
                case 2: presentHour = 26
                case 3: presentHour = 27
                default: break
            }
        }
        
        var lastHour: Int!
        if settings.object(forKey: "timeForDivideLine") != nil {
            lastHour = settings.integer(forKey: "timeForDivideLine")
        } else {
            lastHour = presentHour
        }
        
        if lastHour <= 3 {
            switch lastHour {
                case 0: lastHour = 24
                case 1: lastHour = 25
                case 2: lastHour = 26
                case 3: lastHour = 27
                default: break
            }
        }
        
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
                self.attrText.insert(NSAttributedString(
                    string: "---------↑\(lastHour!)-\(presentHour)時合計: \(hourSum)pt---------\n"),
                    at: attrText.length
                )
                ptPerHourArray.append(lastPt)
                settings.set(ptPerHourArray, forKey: "ptPerHourArray")
            }
            for i in 0..<gotPointArray.count {
                let gotPtText = NSMAttrStr(string: "[\(timeString)] +\(gotPointArray[i].pt)pt【x\(settings.integer(forKey: "modeSwitcher")+1)】: \(gotPointArray[i].item)\n")
                gotPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSMakeRange(0, gotPtText.length))
                self.attrText.insert(gotPtText, at: attrText.length)
            }
            gotPointArray.removeAll()
            self.attrText.insert(NSMAttrStr(string: "[\(timeString)] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
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
                let consumedPtText = NSMAttrStr(string: "[\(timeString)] -\(usedPointArray[i].pt)pt: \(usedPointArray[i].item)\n")
                consumedPtText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, consumedPtText.length))
                self.attrText.insert(consumedPtText, at: attrText.length)
            }
            usedPointArray.removeAll()
            self.attrText.insert(NSMAttrStr(string: "[\(timeString)] 現在: \(String(roadPoints()))pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        }
        
        settings.set(presentHour, forKey: "timeForDivideLine")
        
        // テキストログをuserDefaultsに保存
        let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
        settings.set(archivedText, forKey: "DebugLog")
    }

    //MARK: - StoryBoard / Parts
    
    //ptParts
    @IBOutlet weak var ptlabelStack: UIStackView!
    @IBOutlet weak var pointLabel: UITextField!
    //pptParts
    @IBOutlet weak var poolingPointLabel: UILabel!
    @IBOutlet weak var pptMultiplierButton: UIButton!
    //VCTransitionButtons
    @IBOutlet weak var shopButton: UIButton!
    @IBOutlet weak var missionButton: UIButton!
    //sptParts
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var currentSptLabel: UITextField!
    @IBOutlet weak var addingSptLabel: UITextField!
    //debugLog
    @IBOutlet weak var debugLog: UITextView!
    //effectButtons
    @IBOutlet weak var effectStack: UIStackView!
    @IBOutlet weak var angerEffectBtn: UIButton!
    @IBOutlet weak var exploreEffectBtn: UIButton!
    @IBOutlet weak var heartEffectBtn: UIButton!
    
    //MARK: - StoryBoard / Functions
    
    @IBAction func whenPointLabelEdited(_ sender: UITextField) {
        if pointLabel.text?.isEmpty != true {
            settings.set(pointLabel.text!, forKey: "storePoints")
            self.attrText.insert(NSMAttrStr(string: "[\(catchTime())] 現在: \(pointLabel.text!)pts\n"), at: attrText.length)
            debugLog.attributedText = self.attrText
        } else {
            pointLabel.text = String(roadPoints())
        }
    }
    
    @IBAction func currentSptEdited(_ sender: Any) {
        if let text = currentSptLabel.text {
            currentSpt = Int(text)!
            
            self.attrText.insert(NSAttributedString(string: "現在Spt: \(currentSpt)spt\n"), at: attrText.length)
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
            debugLog.attributedText = attrText
            
            settings.set(currentSpt, forKey: "spt")
            judgeSptRank()
        }
    }
    
    @IBAction func addingSptEdited(_ sender: Any) {
        if let text = addingSptLabel.text {
            let consumePtText : Int
            if let text_db = Double(text) {
                consumePtText = Int(text_db * settings.double(forKey: "moneyMultiplier"))
            } else {
                addingSptLabel.text = ""
                return
            }
            //ログに消費予定のptを表示
            self.attrText.insert(NSAttributedString(
                string: "消費予定pt: \(consumePtText)pt\n"),
                at: attrText.length
            )
            
            // spt更新（ランクも変われば更新）
            currentSpt += Int(text)!
            self.attrText.insert(NSAttributedString(string: "現在Spt: \(currentSpt)spt (+\(text))\n"), at: attrText.length)
            print(currentSpt)
            settings.set(currentSpt, forKey: "spt")
            judgeSptRank()
            
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
            debugLog.attributedText = attrText
            
            //各ラベルに反映
            currentSptLabel.text = String(currentSpt)
            addingSptLabel.text = ""
        }
    }
    @IBAction func currencyButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "SBSC/Rank/Count", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (tf: UITextField) -> Void in
            tf.placeholder = "Subscription_Price"
        }
        alert.textFields![0].text = String(self.settings.integer(forKey: "subscPrice"))
        
        alert.addTextField { (tf: UITextField) -> Void in
            tf.placeholder = "Spt_Rank"
        }
        alert.textFields![1].text = String(self.settings.integer(forKey: "sptRank"))
        
        alert.addTextField { (tf: UITextField) -> Void in
            tf.placeholder = "Rank_count"
        }
        alert.textFields![2].text = String(self.settings.integer(forKey: "sptCount"))
        
        let alertAction = UIAlertAction(title: "OK", style: .default) {(action: UIAlertAction) -> Void in
            if let text0 = alert.textFields![0].text {
                if let num = Int(text0) {
                    self.settings.set(num, forKey: "subscPrice")
                }
            }
            if let text1 = alert.textFields![1].text {
                if let num = Int(text1) {
                    self.settings.set(num, forKey: "sptRank")
                    self.settings.set(self.sptRankData[num], forKey: "moneyMultiplier")
                    print(self.sptRankData[num]!)
                    self.currencyButton.setTitle("x\(self.settings.double(forKey: "moneyMultiplier"))", for: .normal)
                }
            }
            if let text2 = alert.textFields![2].text {
                if let num = Int(text2) {
                    self.settings.set(num, forKey: "sptCount")
                }
            }
        }
        alert.addAction(alertAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func angerBtnTapped(_ sender: Any) {
        effectBtnTapped(0, angerEffectBtn, "\u{1F534}")
    }
    @IBAction func exploreBtnTapped(_ sender: Any) {
        effectBtnTapped(1, exploreEffectBtn, "\u{1F537}")
    }
    @IBAction func heartBtnTapped(_ sender: Any) {
        effectBtnTapped(2, heartEffectBtn, "\u{1F49A}")
    }
    func effectBtnTapped(_ num: Int, _ btn: UIButton, _ effect: String){
        let alert = UIAlertController(title: effect, message: nil, preferredStyle: .alert)
        for i in 0...2 {
            alert.addTextField { (tf: UITextField) -> Void in
                tf.text = String(self.effectsCount[num][i])
            }
        }
        let alertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            var counts = [0,0,0]
            for i in 0...2 {
                if let count : Int = Int(alert.textFields![i].text!) {
                    counts[i] = count
                }
            }
            self.effectsCount[num] = counts
            self.settings.set(self.effectsCount, forKey: "effectsCount")
            var text = ""
            for j in 0 ..< 2 {
                text += "\(self.effectStrs[num][j])x \(self.effectsCount[num][j])\n"
            }
            text += "\(self.effectStrs[num][2])x \(self.effectsCount[num][2])"
            btn.setTitle(text, for: .normal)
            let log = NSMAttrStr(string: "Effect: \(self.effectStrs[num][0])x\(counts[0]) \(self.effectStrs[num][1])x\(counts[1]) \(self.effectStrs[num][2])x\(counts[2])\n", attributes: [.foregroundColor : UIColor.blue])
            self.attrText.insert(log, at: self.attrText.length)
            self.debugLog.attributedText = self.attrText
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: self.debugLog.attributedText!, requiringSecureCoding: false)
            self.settings.set(archivedText, forKey: "DebugLog")
            self.debugLog.scrollRangeToVisible(NSRange(location: self.debugLog.attributedText.length-1, length: 1))
        }
        alert.addAction(alertAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
        if debugLog.isFirstResponder || currentSptLabel.isFirstResponder || addingSptLabel.isFirstResponder {
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
        if debugLog.isFirstResponder || currentSptLabel.isFirstResponder || addingSptLabel.isFirstResponder {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    //sptRankが変動したか確認(保存もする)
    func judgeSptRank() -> Void {
        
        var tempRank = 0
        var moneyMultiplier : Double = 1.0
        
        if      currentSpt >= 12000 {
            overCounter = (currentSpt - 12000) / 3000
            tempRank = 6; moneyMultiplier = 5.0
        }
        else if currentSpt >= 10000 { tempRank = 5; moneyMultiplier = 4.0}
        else if currentSpt >= 7000  { tempRank = 4; moneyMultiplier = 3.0}
        else if currentSpt >= 5000  { tempRank = 3; moneyMultiplier = 2.0}
        else if currentSpt >= 3000  { tempRank = 2; moneyMultiplier = 1.5}
        else if currentSpt >= 2000  { tempRank = 1; moneyMultiplier = 1.2}
        else if sptRank == 1        { tempRank = 1; moneyMultiplier = 1.2}
        else                        { tempRank = 0; moneyMultiplier = 1.0}
        
        if tempRank != sptRank {
            //　ログに履歴表示
            self.attrText.insert(NSAttributedString(string: "補正レベルが変動しました: \(sptRank) -> \(tempRank) [x\(moneyMultiplier)]\n"), at: attrText.length)
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
            debugLog.attributedText = attrText
            self.debugLog.scrollRangeToVisible(NSRange(location: self.debugLog.attributedText.length-1, length: 1))
            
            // ランク変動
            sptRank = tempRank
            
            // カウント更新
            if (sptRank <= 1) { sptCount = 1 } else { sptCount = 2 + overCounter}
            
            //倍率更新
            currencyButton.setTitle("x\(moneyMultiplier)", for: .normal)
            settings.set(moneyMultiplier, forKey: "moneyMultiplier")
            
            //データ保存
            settings.set(sptRank, forKey: "sptRank")
            settings.set(sptCount, forKey: "sptCount")
            print(sptCount)
            print(sptRank)
        }
    }
    
    func resetSpt() -> Void {
        var moneyMultiplier : Double = 1.0
        switch sptRank {
            case 6:
                if sptCount > 2 {
                    currentSpt = 12000 +
                                 (sptCount-1)/2 * 3000
                }
                moneyMultiplier = 5.0;
            case 5: currentSpt = 10000; moneyMultiplier = 4.0;
            case 4: currentSpt = 7000;  moneyMultiplier = 3.0;
            case 3: currentSpt = 5000;  moneyMultiplier = 2.0;
            case 2: currentSpt = 3000;  moneyMultiplier = 1.5;
            case 1: currentSpt = 0;     moneyMultiplier = 1.2;
            case 0: currentSpt = 0;     moneyMultiplier = 1.0;
            default:currentSpt = 0;
        }
        currencyButton.setTitle("x\(moneyMultiplier)", for: .normal)
        settings.set(currentSpt, forKey: "spt")
        settings.set(moneyMultiplier, forKey: "moneyMultiplier")
    }
}

extension ViewController {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == debugLog {
            attrText = debugLog.attributedText!.mutableCopy() as! NSMAttrStr
            let archivedText = try! NSKeyedArchiver.archivedData(withRootObject: debugLog.attributedText!, requiringSecureCoding: false)
            settings.set(archivedText, forKey: "DebugLog")
        }
    }
    
}
