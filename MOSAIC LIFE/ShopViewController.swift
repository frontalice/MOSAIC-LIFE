//
//  ShopViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ShopViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIPickerViewDelegate, UIPickerViewDataSource {

    //MARK: - 保存データ関連

    
    let userDefaults = UserDefaults.standard
    var shopLists: [(shopList: [(item: String, pt: Int)], listName: String)] = [([("ポイントを消費", 100)],"TestSection")]
//    var shopList = [(item: String, pt: Int)]()
    var consumedPtHistory = Array<(item:String, pt:Int)>()
    
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
    
    //セルの生成
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        cell.textLabel?.text = shopLists[indexPath.section].shopList[indexPath.row].item
        cell.detailTextLabel?.text = String(shopLists[indexPath.section].shopList[indexPath.row].pt)
        return cell
    }
    
    //Editタップ時編集モードへ
    override func setEditing(_ editing: Bool, animated: Bool) {
        super .setEditing(editing, animated: true)
        self.tableView.setEditing(editing, animated: true)
        disableGlassMode()
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
        saveTableViewData()
    }
    
//    //セル移動の制限: とりあえず同セクション間での移動のみに留める
//    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
//        if sourceIndexPath.section == proposedDestinationIndexPath.section {
//            return proposedDestinationIndexPath
//        }
//        return sourceIndexPath
//    }
    /*
     セルを動かしてるとき、
     移動中セルのセクションとその真下のセルのセクションが一致している場合は空きセルの場所がproposedDestinationIndexPathになり、
     セクションが一致してない場合は空きセルの場所は変化しない（sourceIndexPathのまま）、的な？
    */
    
    // isEditing = false: セルをタップでポイント獲得
    // isEditing = true:  既存セルの編集
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tableView.isEditing {
            
            //userDefaultsに残ptのデータを保存
            let setting = UserDefaults.standard
            var presentPoint: Int = setting.integer(forKey: "storePoints")
            let consumeItem: String = shopLists[indexPath.section].shopList[indexPath.row].item
            let consumePoint: Int = shopLists[indexPath.section].shopList[indexPath.row].pt
            
            presentPoint -= consumePoint
            setting.set(presentPoint, forKey: "storePoints")
            setting.synchronize()
            
            // 画面左下のラベルを更新
            pointLabel.title = "\(String(presentPoint)) pt"
            
            //ライフログを直接更新
            //メイン画面vcにexchangedPtHistoryを渡す
            let nvc = self.navigationController!
            let vc = nvc.viewControllers[0] as! ViewController
            vc.usedPointArray.append((consumeItem, consumePoint))
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
                pt.text = String(self.shopLists[indexPath.section].shopList[indexPath.row].pt)
            }
            var alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                let itemTf = alert.textFields![0]
                let ptTf = alert.textFields![1]
                if let itemText = itemTf.text, let ptText = ptTf.text {
                    if let ptInt = Int(ptText) {
                        self.shopLists[indexPath.section].shopList[indexPath.row].item = itemText
                        self.shopLists[indexPath.section].shopList[indexPath.row].pt = ptInt
                        self.tableView.reloadData()
                        self.saveTableViewData()
                    } else {
                        self.showAlert("ptに文字を入れるな")
                    }
                } else {
                    self.showAlert("追加に失敗しました")
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
        for i in 0..<shopLists.count {
            let convertedList: [[String: Any]] = shopLists[i].shopList.map{["item": $0.item, "pt": $0.pt]}
            userDefaults.set(convertedList, forKey: "shopMemory\(String(i))")
            userDefaults.set(shopLists[i].listName, forKey: "categoryName\(String(i))_shop")
//            print(userDefaults.dictionaryRepresentation().filter { $0.key.hasPrefix("shopMemory") })
        }
        userDefaults.set(shopLists.count, forKey: "categoryCount_shop")
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
        
        // +とEditボタン追加
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
//        let sortButton: UIBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(self.sortButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        // リスト情報をmissionMemoryから読み込み
        let categoryCount: Int = userDefaults.integer(forKey: "categoryCount_shop")
//        print("CategoryCount: \(categoryCount)")
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
                        continue
                    }
    //                print(shopList)
                }
            } else {
                //保存データが無い場合、アラート表示
                showAlert("データの読み込みに失敗しています")
            }
        }
        
        tableView.reloadData()
        
        //編集中でもセルを選択できるようにする
        self.tableView.allowsSelectionDuringEditing = true
        
        // 残りptを取得
        let setting = UserDefaults.standard
        let presentPoint: Int = setting.integer(forKey: "storePoints")
        pointLabel.title = "\(String(presentPoint)) pt"
        
        //グラスモード -> false
        glassModeIsEnabled = false
        glassButton.tintColor = .systemGray
//        print("glass mode is \(glassModeIsEnabled)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // メイン画面vcにconsumedPtHistoryを渡す
        let nvc = self.navigationController!
        let vc = nvc.viewControllers[0] as! ViewController
        for i in 0..<consumedPtHistory.count {
            vc.usedPointArray.append(consumedPtHistory[i])
//            print(element)
        }
        //ptHistoryの初期化
        consumedPtHistory.removeAll()
        
        //バフされたptの初期化
        if glassModeIsEnabled == true {
            for i in 0..<shopLists.count {
                if shopLists[i].listName.contains("Coding") {
                    for n in 0..<shopLists[i].shopList.count {
                        shopLists[i].shopList[n].pt = Int(Float(shopLists[i].shopList[n].pt) / 0.9)
                    }
                }
            }
        }
    }
    
    // MARK: - StoryBoard

    @IBOutlet weak var pointLabel: UIBarLabel!
    @IBOutlet weak var glassButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - UI部品
    
    //ミッションを追加: alertで入力
    @objc func plusButtonTapped(_ sender: UIBarButtonItem){
        disableGlassMode()
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
            
            if let itemText = itemTf.text, let ptText = ptTf.text {
                if let ptInt = Int(ptText) {
                    if sectionTf.text != "新しいカテゴリを追加" {
                        //既存のカテゴリに追加 -> そのまま
                        self.shopLists.removeLast()
                        self.addItem(itemText, ptInt, self.selectedSectionIndex)
                    } else {
                        //カテゴリを新しく作成してから追加
                        self.createCategory(itemText, ptInt)
                    }
                } else {
                    self.showAlert("ptに文字を入れるな")
                }
            } else {
                self.showAlert("追加に失敗しました")
            }
        }
        
        alert.addAction(alertAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) {(action: UIAlertAction) -> Void in
            self.shopLists.removeLast()
        })
        present(alert, animated: true, completion: nil)
    }
    
    var glassModeIsEnabled : Bool = false
    
    func disableGlassMode(){
        if glassModeIsEnabled == true {
            glassModeIsEnabled = false
            for i in 0..<shopLists.count {
                if shopLists[i].listName.contains("Gaming") {
                    for n in 0..<shopLists[i].shopList.count {
                        shopLists[i].shopList[n].pt = Int(Float(shopLists[i].shopList[n].pt) / 0.9)
                    }
                    tableView.reloadData()
                }
            }
        }
    }
    
    @IBAction func glassButtonTapped(_ sender: Any) {
        glassModeIsEnabled = !glassModeIsEnabled
//        print("glass button tapped, glassmode is \(glassModeIsEnabled)")
        
        if glassModeIsEnabled == true {
            glassButton.tintColor = .systemBlue
            for i in 0..<shopLists.count {
                if shopLists[i].listName.contains("Gaming") {
                    for n in 0..<shopLists[i].shopList.count {
                        shopLists[i].shopList[n].pt = Int(Float(shopLists[i].shopList[n].pt) * 0.9)
                    }
                    tableView.reloadData()
//                    print(shopLists[i].shopList)
                }
            }
        } else {
            glassButton.tintColor = .systemGray
            for i in 0..<shopLists.count {
                if shopLists[i].listName.contains("Gaming") {
                    for n in 0..<shopLists[i].shopList.count {
                        shopLists[i].shopList[n].pt = Int(Float(shopLists[i].shopList[n].pt) / 0.9)
                    }
                    tableView.reloadData()
                }
            }
        }
    }
    
    //　アラート: エラー表示
    func showAlert(_ message: String){
        let alert : UIAlertController = UIAlertController(title: "警告", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default, handler: nil)
        alert.addAction(okAction)
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
//                self.shopLists.append((shopList: [(item, pt)], categoryText))
                self.shopLists.removeLast()
                self.tableView.reloadData()
                self.saveTableViewData()
            } else {
                self.showAlert("なんか書いてくれ")
            }
        }
        
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
}
