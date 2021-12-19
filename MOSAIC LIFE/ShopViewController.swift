//
//  ShopViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ShopViewController: MLBaseViewController,UITableViewDelegate,UITableViewDataSource,UIPickerViewDelegate, UIPickerViewDataSource {

    //MARK: - 保存データ関連

    
    let userDefaults = UserDefaults.standard
    var shopLists: [(shopList: [(item: String, pt: Int)], listName: String)] = [([("ポイントを消費", 100)],"TestSection")]
    var ptList: [String : [Int]] = ["":[]]
//    var shopList = [(item: String, pt: Int)]()
    var consumedPtHistory = Array<(item:String, pt:Int)>()
    
    var buffArray: [(buffName: String, magnification: String, category: String, date: Date)] = Array<(String, String, String, Date)>()
    
    var isBuffApplicated: Bool = false
    
    var poolingPoint = 0
    var moneyMultiplier = 1.0
    
    //MARK: - TableView関連

    //セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return shopLists.count
    }
    
    //セクション内のセルはいくつ？
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopLists[section].shopList.count
    }
    
    //セクション名
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return shopLists[section].listName
    }
    
    //セクションヘッダの色
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.systemGreen
    }
    
    //セルの生成
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        cell.textLabel?.text = shopLists[indexPath.section].shopList[indexPath.row].item
        cell.detailTextLabel?.text = String(shopLists[indexPath.section].shopList[indexPath.row].pt)
        
        // 不足時グレーアウト
        if shopLists[indexPath.section].shopList[indexPath.row].pt > userDefaults.integer(forKey: "storePoints") {
            cell.backgroundColor = UIColor.systemGray
        }
        
        // ppt消費可能時水色
        if userDefaults.integer(forKey: "poolingPoint") >= shopLists[indexPath.section].shopList[indexPath.row].pt && shopLists[indexPath.section].shopList[indexPath.row].pt > userDefaults.integer(forKey: "storePoints") {
            cell.backgroundColor = UIColor {_ in return #colorLiteral(red: 0.3529411765, green: 1, blue: 0.9803921569, alpha: 1)}
        }
        
        return cell
    }
    
    //Editタップ時編集モードへ
    override func setEditing(_ editing: Bool, animated: Bool) {
        super .setEditing(editing, animated: true)
        self.tableView.setEditing(editing, animated: true)
        tableView.reloadData()
    }
    
    //削除できるセル: 全部
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //セル削除時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        shopLists[indexPath.section].shopList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        // セクション内のセル数が0の場合、セクションを消去
        if shopLists[indexPath.section].shopList.count == 0 {
            shopLists.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
        saveTableViewData()
    }
    
    //移動できるセル: 全部
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //セル移動時の処理
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let targetCell = shopLists[sourceIndexPath.section].shopList[sourceIndexPath.row]
        shopLists[sourceIndexPath.section].shopList.remove(at: sourceIndexPath.row)
        shopLists[destinationIndexPath.section].shopList.insert(targetCell, at: destinationIndexPath.row)
        if shopLists[sourceIndexPath.section].shopList.count == 0 {
            shopLists.remove(at: sourceIndexPath.section)
            tableView.deleteSections(IndexSet(integer: sourceIndexPath.section), with: .automatic)
        }
        saveTableViewData()
    }
    
    func deleteSectionIfCountIsZero(tableView: UITableView, indexPath: IndexPath) {
        if shopLists[indexPath.section].shopList.count == 0 {
            shopLists.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }
    
    // isEditing = false: セルをタップでポイント消費
    // isEditing = true:  既存セルの編集
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tableView.isEditing {
            
            //userDefaultsに残ptのデータを保存
            let setting = UserDefaults.standard
            var presentPoint: Int = setting.integer(forKey: "storePoints")
            var consumeItem: String = shopLists[indexPath.section].shopList[indexPath.row].item
            let consumePoint: Int = shopLists[indexPath.section].shopList[indexPath.row].pt
            
            if consumePoint > presentPoint {
                if consumePoint > self.poolingPoint {
                    //選択エフェクトを解除
                    tableView.deselectRow(at: indexPath, animated: true)
                    
                    return
                } else {
                    let alert = UIAlertController(title: nil, message: "プールptで購入する？", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                        self.poolingPoint -= consumePoint
                        setting.set(self.poolingPoint, forKey: "poolingPoint")
                        self.pointLabel.title = "\(String(presentPoint)) pt / \(String(self.poolingPoint)) ppt"
                        self.tableView.reloadData()
                        self.tableView.deselectRow(at: indexPath, animated: true)
                        
                        // ログ更新（ppt消費時用）
                        let nvc = self.navigationController!
                        let vc = nvc.viewControllers[0] as! MainViewController
                        consumeItem = "[ppt消費]" + consumeItem
                        vc.usedPointArray.append((consumeItem, consumePoint))
                        
                        // 切り取り線向け処理
                        if let savedPphArray = self.userDefaults.array(forKey: "ptPerHourArray") as? [Int] {
                            vc.ptPerHourArray = savedPphArray
                        }
                        vc.ptPerHourArray.append(consumePoint)
                        self.userDefaults.set(vc.ptPerHourArray, forKey: "ptPerHourArray")
                        vc.writeDebugLog()
                        
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                    alert.addAction(alertAction)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel){
                        (action: UIAlertAction) -> Void in
                        tableView.deselectRow(at: indexPath, animated: true)
                    })
                    present(alert, animated: true, completion: nil)
                    
                    return
                }
            }
            
            presentPoint -= consumePoint
            setting.set(presentPoint, forKey: "storePoints")
            tableView.reloadData()
            
            // 画面左下のラベルを更新
            pointLabel.title = "\(String(presentPoint)) pt / \(String(self.poolingPoint)) ppt"
            
            //ライフログを直接更新
            //メイン画面vcにexchangedPtHistoryを渡す
            let nvc = self.navigationController!
            let vc = nvc.viewControllers[0] as! MainViewController
            vc.usedPointArray.append((consumeItem, consumePoint))
            
            // 切り取り線向け処理
            if let savedPphArray = userDefaults.array(forKey: "ptPerHourArray") as? [Int] {
                vc.ptPerHourArray = savedPphArray
            }
            vc.ptPerHourArray.append(consumePoint)
            userDefaults.set(vc.ptPerHourArray, forKey: "ptPerHourArray")
            vc.writeDebugLog()
            
            //消費履歴を更新
//            consumedPtHistory.append((consumeItem,consumePoint))
            
            //選択エフェクトを解除
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            // 編集モード時にタップしたらミッション名やポイントを変更できるようにする
//            print("editing now")
            let alert = UIAlertController(title: "Itemの編集", message: "Item名と消費ptの編集", preferredStyle: .alert)
            alert.addTextField { (mission: UITextField) -> Void in
                mission.placeholder = "Item Name"
                mission.text = self.shopLists[indexPath.section].shopList[indexPath.row].item
            }
            alert.addTextField { (pt: UITextField) -> Void in
                pt.placeholder = "Points"
                
                // バフ適用時、ptを初期化
                var rawpt = self.shopLists[indexPath.section].shopList[indexPath.row].pt
                
                if self.isBuffApplicated {
                    if let txt = alert.textFields![0].text {
                        rawpt = self.disableSingleBuff(text: txt, num: rawpt, k: indexPath.section)
//                        if txt.range(of: "\u{1F4B0}") == nil {
//                            let buffedCategory = self.buffArray.map{$0.category}
//                            if buffedCategory.contains(self.shopLists[indexPath.section].listName) {
//                                let index = buffedCategory.firstIndex(of: self.shopLists[indexPath.section].listName)
//                                rawpt = Int("\(Decimal(rawpt) / (Decimal(string: self.buffArray[index!].magnification)! * 10) * 10)")!
//                            }
//                        }
                    }
                }
                pt.text = String(rawpt)
                
            }
            let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                let itemTf = alert.textFields![0]
                let ptTf = alert.textFields![1]
                if let itemText = itemTf.text, let ptText = ptTf.text {
                    if var ptInt = Int(ptText) {
                        //バフ適用対象の場合、バフをかける
                        if self.isBuffApplicated {
                            ptInt = self.applySingleBuff(text: itemText, category: self.shopLists[indexPath.section].listName, num: ptInt)
                            
//                            if itemText.range(of: "\u{1F4B0}") == nil {
//                                let buffedCategory = self.buffArray.map{$0.category}
//                                for i in 0..<buffedCategory.count {
//                                    if self.shopLists[indexPath.section].listName == buffedCategory[i] {
//                                        let index = buffedCategory.firstIndex(of: self.shopLists[indexPath.section].listName)
//                                        //                                let intMag = self.buffArray[index!].magnification * 100.0
//                                        ptInt = Int("\(Decimal(ptInt) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!
//                                    }
//                                }
//                            }
                        }
                        
                        self.shopLists[indexPath.section].shopList[indexPath.row].item = itemText
                        self.shopLists[indexPath.section].shopList[indexPath.row].pt = ptInt
                        self.tableView.reloadData()
                        self.saveTableViewData()
                    } else {
                        self.showMessage("ptに文字を入れるな")
                    }
                } else {
                    self.showMessage("追加に失敗しました")
                }
            }
            
            alert.addAction(alertAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    //ミッションを追加: リストに追加
    func addItem(_ item:String, _ pt:Int, _ section:Int){
        // shopListに追加
        shopLists[section].shopList.append((item, pt))
        // TableViewに追加
        tableView.reloadData()
        //userDefaults更新
        saveTableViewData()
    }
    
    func saveTableViewData(){
        makeRawData()
        
        for i in 0..<shopLists.count {
            let convertedList: [[String: Any]] = shopLists[i].shopList.map{["item": $0.item, "pt": $0.pt]}
            userDefaults.set(convertedList, forKey: "shopMemory\(String(i))")
            userDefaults.set(shopLists[i].listName, forKey: "categoryName\(String(i))_shop")
//            print(userDefaults.dictionaryRepresentation().filter { $0.key.hasPrefix("shopMemory") })
        }
        userDefaults.set(shopLists.count, forKey: "categoryCount_shop")
        
        enchantData()
    }
    
    //MARK: - PickerView関連

    // pickerViewの作成
    let categorySelectPickerView = UIPickerView()
    let categoryInsertPickerView = UIPickerView()
    
    //pickerView: 何行？
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return shopLists.count
    }
    
    //pickerView: 何列？
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //pickerView: 表示データ
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return shopLists[row].listName
    }
    
    var selectedSectionIndex: Int = 0
    
    //pickerView: データ選択時の挙動
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        editingTextField.text = shopLists[row].listName
        selectedSectionIndex = row
    }
    
    var editingTextField: UITextField = UITextField()
    
    //pickerView: Doneボタン押すとキーボードしまう
    @objc func doneButtonOnToolBarTapped(_ sender: UIBarButtonItem){
        editingTextField.endEditing(true)
    }
    
    //MARK: - ライフサイクル
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        userDefaults.register(defaults: ["moneyMultiplier" : 2.0])
        
        // +とEditボタン追加
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
//        let sortButton: UIBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(self.sortButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        // リスト情報をmissionMemoryから読み込み
        let categoryCount: Int = userDefaults.integer(forKey: "categoryCount_shop")
        for i in 0..<categoryCount {
            if userDefaults.object(forKey: "shopMemory\(String(i))") != nil {
                if let dicList = userDefaults.object(forKey: "shopMemory\(String(i))") as? [[String: Any]] {
    //                print(dicList)
                    // 初期化したshopListsにはshopLists[1]以降が無いので都度追加
                    if i > 0 {
                        self.shopLists.append((shopList: [], listName: ""))
                    }
                    self.shopLists[i].shopList = dicList.map{(item: $0["item"] as! String, pt: $0["pt"] as! Int)}
                    if let listName = userDefaults.string(forKey: "categoryName\(String(i))_shop") {
                        self.shopLists[i].listName = listName
                    } else {
                        self.shopLists[i].listName = "UnnamedCategory\(String(i))"
                    }
                }
            } else {
                //保存データが無い場合、アラート表示
                showMessage("データの読み込みに失敗しています")
            }
        }
        
        //ptListsに反映
        for i in 0..<shopLists.count {
            var ptArray = Array<Int>()
            shopLists[i].shopList.forEach({elem in ptArray.append(elem.pt)})
            ptList.updateValue(ptArray, forKey: shopLists[i].listName)
        }
        
        // バフ: userDefaultsから取得
        if let dicList = userDefaults.object(forKey: "buffData") as? [[String : Any]] {
            self.buffArray = dicList.map{(buffName: $0["name"] as! String, magnification: $0["mag"] as! String, category: $0["category"] as! String, date: $0["date"] as! Date)}
            if !buffArray.isEmpty {
                isBuffApplicated = true
                applyMultiBuff()
            }
        }
        
        if #available(iOS 15, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        // TableViewを表示
        tableView.reloadData()
        
        //編集中でもセルを選択できるようにする
        self.tableView.allowsSelectionDuringEditing = true
        
        // 残りptを取得
        let setting = UserDefaults.standard
        let presentPoint: Int = setting.integer(forKey: "storePoints")
        if setting.object(forKey: "poolingPoint") != nil {
            self.poolingPoint = setting.integer(forKey: "poolingPoint")
        }
        pointLabel.title = "\(String(presentPoint)) pt / \(String(self.poolingPoint)) ppt"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        syncBarAppearance(.systemGreen)
        moneyMutiplierButton.title = "x\(userDefaults.double(forKey: "moneyMultiplier"))"
    }
    
    func syncBarAppearance(_ color : UIColor){
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            // NavigationBarの背景色の設定
            appearance.backgroundColor = color
            // NavigationBarのタイトルの文字色の設定
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            
//            let tbAppearance = UIToolbarAppearance()
//            tbAppearance.configureWithOpaqueBackground()
//            tbAppearance.backgroundColor = color
//            self.navigationController?.toolbar.standardAppearance = tbAppearance
//            self.navigationController?.toolbar.scrollEdgeAppearance = tbAppearance
        }
    }
    
    // MARK: - バフ関連
    
    func makeRawData() {
        
        //バフされたptの初期化: Settingバフ
        if isBuffApplicated {
            disableMultiBuff()
        }
        
        tableView.reloadData()
    }
    
    func disableMultiBuff(){
        let buffedCategory = buffArray.map{$0.category}
        for i in 0..<shopLists.count {
            if buffedCategory.contains(shopLists[i].listName) {
                let index = buffedCategory.firstIndex(of: shopLists[i].listName)
                for n in 0..<shopLists[i].shopList.count {
                    if shopLists[i].shopList[n].item.range(of: "\u{1F4B0}") == nil {
                        shopLists[i].shopList[n].pt = Int("\(Decimal(shopLists[i].shopList[n].pt) / (Decimal(string: self.buffArray[index!].magnification)! * 10) * 10)")!
                    }
                }
            }
        }
    }
    
    func disableSingleBuff(text: String, num: Int, k: Int) -> Int{
        if text.range(of: "\u{1F4B0}") == nil {
            let buffedCategory = self.buffArray.map{$0.category}
            if buffedCategory.contains(self.shopLists[k].listName) {
                let index = buffedCategory.firstIndex(of: self.shopLists[k].listName)
                return Int("\(Decimal(num) / (Decimal(string: self.buffArray[index!].magnification)! * 10) * 10)")!
            }
        }
        return num
    }
    
    func enchantData() {
        
        //Settingバフ
        if isBuffApplicated {
            applyMultiBuff()
        }
        
        tableView.reloadData()
    }
    
    func applyMultiBuff(){
        let buffedCategory = buffArray.map{$0.category}
        for i in 0..<shopLists.count {
            if buffedCategory.contains(shopLists[i].listName) {
                let index = buffedCategory.firstIndex(of: shopLists[i].listName)
                for n in 0..<shopLists[i].shopList.count {
                    if shopLists[i].shopList[n].item.range(of: "\u{1F4B0}") == nil {
                        shopLists[i].shopList[n].pt = Int("\(Decimal(shopLists[i].shopList[n].pt) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!
                    }
                }
            }
        }
    }
    
    
    func applySingleBuff(text: String, category: String, num: Int) -> Int{
        if text.range(of: "\u{1F4B0}") == nil {
            let buffedCategory = self.buffArray.map{$0.category}
            if buffedCategory.contains(category) {
                let index = buffedCategory.firstIndex(of: category)
                return Int("\(Decimal(num) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!
            }
        }
        return num
    }
    
    // MARK: - StoryBoard

    @IBOutlet weak var pointLabel: UIBarLabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var moneyMutiplierButton: UIBarButtonItem!
    
    //MARK: - UI部品
    
    //ミッションを追加: alertで入力
    @objc func plusButtonTapped(_ sender: UIBarButtonItem){
        tableView.reloadData()
        let alert = UIAlertController(title: "Itemの追加", message: "Item名と消費ptを入力", preferredStyle: .alert)
        alert.addTextField { (item: UITextField) -> Void in
            item.placeholder = "Item Name"
        }
        alert.addTextField { (pt: UITextField) -> Void in
            pt.placeholder = "Points"
        }
        alert.addTextField { (section: UITextField) -> Void in
            section.placeholder = "Section"
        }
        
        // shopLists末尾にセクション追加用要素を追加
        shopLists.append((shopList: [], listName: "新しいカテゴリを追加"))
        
        //pickerViewに関する処理
        self.editingTextField = alert.textFields![2]
        categorySelectPickerView.dataSource = self
        categorySelectPickerView.delegate = self
        categorySelectPickerView.selectRow(0, inComponent: 0, animated: true)

        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonOnToolBarTapped(_:)))
        toolbar.setItems([doneButton], animated: true)
        toolbar.sizeToFit()

        //pickerViewに関する処理: 実装
        alert.textFields![2].inputAccessoryView = toolbar
        alert.textFields![2].inputView = categorySelectPickerView
        
        //OKボタンを押した時の挙動
        let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            let itemTf = alert.textFields![0]
            let ptTf = alert.textFields![1]
            let sectionTf = alert.textFields![2]
            
            if let itemText = itemTf.text, let ptText = ptTf.text, let categoryText = sectionTf.text {
                if var ptInt: Int = Int(ptText) {
                    // バフ適用中のカテゴリに追加する場合
                    if self.isBuffApplicated {
                        ptInt = self.applySingleBuff(text: itemText, category: categoryText, num: ptInt)
                    }
                    // 既存のカテゴリに追加する場合 -> そのまま
                    if sectionTf.text != "新しいカテゴリを追加" {
                        self.shopLists.removeLast()
                        self.addItem(itemText, ptInt, self.selectedSectionIndex)
                    } else {
                    // カテゴリを新しく作成してから追加
                        self.createCategory(itemText, ptInt)
                    }
                } else {
                    self.showMessage("ptに文字を入れるな")
                }
            } else {
                self.showMessage("追加に失敗しました")
            }
        }
        
        alert.addAction(alertAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) {(action: UIAlertAction) -> Void in
            self.shopLists.removeLast()
        })
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func moneyMultiplierButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "倍率変更", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf: UITextField) -> Void in
            tf.placeholder = "Money Multiplier"
        }
        alert.textFields![0].text = String(self.moneyMultiplier)
        
        let alertAction = UIAlertAction(title: "OK", style: .default) {(action: UIAlertAction) -> Void in
            if let text = alert.textFields![0].text {
                if let num = Double(text) {
                    self.moneyMultiplier = num
                    self.userDefaults.set(num, forKey: "moneyMultiplier")
                    self.moneyMutiplierButton.title = "x\(num)"
                } else {
                    self.showMessage("不正な入力です")
                }
            } else {
                self.showMessage("不正な入力です")
            }
        }
        alert.addAction(alertAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // アラート: カテゴリ作成
    func createCategory(_ item: String, _ pt: Int) {
        let alert : UIAlertController = UIAlertController(title: "カテゴリを追加", message: "カテゴリ名を入力", preferredStyle: .alert)
        alert.addTextField { (category: UITextField) -> Void in
            category.placeholder = "Category Name"
        }
        alert.addTextField { (position: UITextField) -> Void in
            position.placeholder = "Insert above..."
        }
        
        //pickerViewに関する処理
        self.editingTextField = alert.textFields![1]
        categoryInsertPickerView.dataSource = self
        categoryInsertPickerView.delegate = self
        categoryInsertPickerView.selectRow(0, inComponent: 0, animated: true)
        
        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonOnToolBarTapped(_:)))
        toolbar.setItems([doneButton], animated: true)
        toolbar.sizeToFit()
        
        //pickerViewに関する処理: 実装
        alert.textFields![1].inputAccessoryView = toolbar
        alert.textFields![1].inputView = categoryInsertPickerView
        
        //OKボタンを押した時の挙動
        let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            if let categoryText = alert.textFields![0].text {
                self.shopLists.insert((shopList: [(item, pt)], categoryText), at: self.selectedSectionIndex)
                self.shopLists.removeLast()
                self.tableView.reloadData()
                self.saveTableViewData()
            } else {
                self.showMessage("なんか書いてくれ")
            }
        }
        
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
}
