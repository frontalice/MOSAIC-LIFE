//
//  MissionViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit
import CoreData

class MissionViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: - 保存データ関連
    
    let userDefaults = UserDefaults.standard
    var missionLists: [(missionList: [(mission: String, pt: Int)], listName: String)] = [([("ポイントを獲得", 100)],"TestSection")]
//    var missionList = [(mission: String, pt: Int)]()
    var exchangedPtHistory = Array<(item:String, pt:Int)>()
    
    var buffArray: [(buffName: String, magnification: String, category: String, date: Date)] = Array<(String, String, String, Date)>()
    
    var isBuffApplicated: Bool = false
    
    //MARK: - TableView関連
    //セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return missionLists.count
    }
    
    //セクション内のセルはいくつ？
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return missionLists[section].missionList.count
    }
    
    //セクション名
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return missionLists[section].listName
    }
    
    //セクションヘッダの色
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.systemTeal
    }
    
    //セルの生成
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        cell.textLabel?.text = missionLists[indexPath.section].missionList[indexPath.row].mission
        cell.detailTextLabel?.text = String(missionLists[indexPath.section].missionList[indexPath.row].pt)
        return cell
    }
    
    //Editタップ時編集モードへ
    override func setEditing(_ editing: Bool, animated: Bool) {
        super .setEditing(editing, animated: true)
        self.tableView.setEditing(editing, animated: true)
    }
    
    //削除できるセル: 全部
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //セル削除時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        missionLists[indexPath.section].missionList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        // セクション内のセル数が0の場合、セクションを消去
        if missionLists[indexPath.section].missionList.count == 0 {
            missionLists.remove(at: indexPath.section)
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
        let targetCell = missionLists[sourceIndexPath.section].missionList[sourceIndexPath.row]
        missionLists[sourceIndexPath.section].missionList.remove(at: sourceIndexPath.row)
        missionLists[destinationIndexPath.section].missionList.insert(targetCell, at: destinationIndexPath.row)
        saveTableViewData()
    }
    
    // isEditing = false: セルをタップでポイント獲得
    // isEditing = true:  既存セルの編集
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tableView.isEditing {
            
            //userDefaultsに残ptのデータを保存
            let setting = UserDefaults.standard
            var presentPoint: Int = setting.integer(forKey: "storePoints")
            let missionItem: String = missionLists[indexPath.section].missionList[indexPath.row].mission
            let missionPoint: Int = missionLists[indexPath.section].missionList[indexPath.row].pt
            
            presentPoint += missionPoint
            setting.set(presentPoint, forKey: "storePoints")
            setting.synchronize()
            
            //画面左下のラベルを更新
            pointLabel.title = "\(String(presentPoint)) pt"
            
            //ライフログを直接更新
            //メイン画面vcにexchangedPtHistoryを渡す
            let nvc = self.navigationController!
            let vc = nvc.viewControllers[0] as! ViewController
            vc.gotPointArray.append((missionItem, missionPoint))
            
            // 切り取り線向け処理
            if let savedPphArray = userDefaults.array(forKey: "ptPerHourArray") as? [Int] {
                vc.ptPerHourArray = savedPphArray
            }
            vc.ptPerHourArray.append(missionPoint)
            userDefaults.set(vc.ptPerHourArray, forKey: "ptPerHourArray")
            vc.writeDebugLog()

            //ptHistoryの初期化
//            exchangedPtHistory.removeAll()
            
//            exchangedPtHistory.append((missionItem,missionPoint))
            
            //選択エフェクトを解除
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            // 編集モード時にタップしたらミッション名やポイントを変更できるようにする
            let alert = UIAlertController(title: "Todoの編集", message: "ToDo名と報酬ptの編集", preferredStyle: .alert)
            alert.addTextField { (mission: UITextField) -> Void in
                mission.placeholder = "Mission Name"
                mission.text = self.missionLists[indexPath.section].missionList[indexPath.row].mission
            }
            alert.addTextField { (pt: UITextField) -> Void in
                pt.placeholder = "Points"
                
                // バフ適用時、ptを初期化
                var rawpt = self.missionLists[indexPath.section].missionList[indexPath.row].pt
                
                if self.isBuffApplicated {
                    let buffedCategory = self.buffArray.map{$0.category}
                    if buffedCategory.contains(self.missionLists[indexPath.section].listName) {
                        let index = buffedCategory.firstIndex(of: self.missionLists[indexPath.section].listName)
                        rawpt = Int("\(Decimal(rawpt) / (Decimal(string: self.buffArray[index!].magnification)! * 10) * 10)")!
                    }
                }
                
                pt.text = String(rawpt)
            }
            let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                let missionTf = alert.textFields![0]
                let ptTf = alert.textFields![1]
                if let missionText = missionTf.text, let ptText = ptTf.text {
                    if var ptInt = Int(ptText) {
                        //バフ適用対象の場合、バフをかける
                        if self.isBuffApplicated {
                            let buffedCategory = self.buffArray.map{$0.category}
                            for i in 0..<buffedCategory.count {
                                if self.missionLists[indexPath.section].listName == buffedCategory[i] {
                                    let index = buffedCategory.firstIndex(of: self.missionLists[indexPath.section].listName)
    //                                let intMag = self.buffArray[index!].magnification * 100.0
                                    ptInt = Int("\(Decimal(ptInt) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!
                                }
                            }
                        }
                        
                        self.missionLists[indexPath.section].missionList[indexPath.row].mission = missionText
                        self.missionLists[indexPath.section].missionList[indexPath.row].pt = ptInt
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
    func addMission(_ mission:String, _ pt:Int, _ section:Int){
        // missionListに追加
        missionLists[section].missionList.append((mission, pt))
        // TableViewに追加
        tableView.reloadData()
        //userDefaults更新
        saveTableViewData()
    }
    
    func saveTableViewData(){
        makeRawData()
        
        for i in 0..<missionLists.count {
            let convertedList: [[String: Any]] = missionLists[i].missionList.map{["mission": $0.mission, "pt": $0.pt]}
            userDefaults.set(convertedList, forKey: "missionMemory\(String(i))")
            userDefaults.set(missionLists[i].listName, forKey: "categoryName\(String(i))")
        }
        userDefaults.set(missionLists.count, forKey: "categoryCount")
        
        enchantData()
    }
    
    //MARK: - PickerView関連
    
    // pickerViewの作成
    let categorySelectPickerView = UIPickerView()
    let categoryInsertPickerView = UIPickerView()
    
    //pickerView: 何行？
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return missionLists.count
    }
    
    //pickerView: 何列？
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //pickerView: 表示データ
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return missionLists[row].listName
    }
    
    var selectedSectionIndex: Int = 0
    
    //pickerView: データ選択時の挙動
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        editingTextField.text = missionLists[row].listName
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
        
        navigationController?.navigationBar.barTintColor = UIColor.systemTeal
        
        // +とEditボタン追加
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
//        let sortButton: UIBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(self.sortButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        // CoreDataから読み込み
        
        
        // リスト情報をmissionMemoryから読み込み
        let categoryCount: Int = userDefaults.integer(forKey: "categoryCount")
        for i in 0..<categoryCount {
            if userDefaults.object(forKey: "missionMemory\(String(i))") != nil {
                
                if let dicList = userDefaults.object(forKey: "missionMemory\(String(i))") as? [[String: Any]] {
                    
                    // 初期化したmissionListsにはmissionLists[1]以降が無いので都度追加
                    if i > 0 {
                        self.missionLists.append((missionList: [], listName: ""))
                    }
                    self.missionLists[i].missionList = dicList.map{(mission: $0["mission"] as! String, pt: $0["pt"] as! Int)}
                    if let listName = userDefaults.string(forKey: "categoryName\(String(i))") {
                        self.missionLists[i].listName = listName
                    } else {
                        self.missionLists[i].listName = "UnnamedCategory\(String(i))"
                    }
                }
                
            } else {
                //保存データが無い場合、アラート表示
                showAlert("データの読み込みに失敗しています")
            }
        }
        
        // CoreData全消去
//        let contxt = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MissionData")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//
//        do {
//            try contxt.execute(deleteRequest)
//            try contxt.save()
//        } catch  {
//            print("Failed to Delete MissionData.")
//        }
        
        // CoreData移行プロセス
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let context = appDelegate.persistentContainer.viewContext
//        for i in 0..<missionLists.count {
//            for j in 0..<missionLists[i].missionList.count {
//                let newItem = MissionData(context: context)
//                newItem.missionName = missionLists[i].missionList[j].mission
//                newItem.pt = Int16(missionLists[i].missionList[j].pt)
//                newItem.multiplier = 1.0
//                newItem.category = missionLists[i].listName
//                do {
//                    try context.save()
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//        }
        
        // バフ: userDefaultsから取得
        if let dicList = userDefaults.object(forKey: "buffData") as? [[String : Any]] {
            self.buffArray = dicList.map{(buffName: $0["name"] as! String, magnification: $0["mag"] as! String, category: $0["category"] as! String, date: $0["date"] as! Date)}
            if !buffArray.isEmpty {
                isBuffApplicated = true
                let buffedCategory = buffArray.map{$0.category}
                for i in 0..<missionLists.count {
                    if buffedCategory.contains(missionLists[i].listName) {
                        let index = buffedCategory.firstIndex(of: missionLists[i].listName)
//                        let intMag = buffArray[index!].magnification * 100
                        let buffedMissionList = missionLists[i].missionList.map{($0.mission, Int("\(Decimal($0.pt) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!)}
                        missionLists[i].missionList = buffedMissionList
                    }
                }
            }
        }
        
        // TableViewを表示
        tableView.reloadData()
        
        //編集中でもセルを選択できるようにする
        self.tableView.allowsSelectionDuringEditing = true
        
        // 残りptを取得
        let setting = UserDefaults.standard
        let presentPoint: Int = setting.integer(forKey: "storePoints")
        pointLabel.title = "\(String(presentPoint)) pt"

    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//        do {
//            let fetchRequest: NSFetchRequest<MissionData> = MissionData.fetchRequest()
//            let dataArray = try context.fetch(fetchRequest)
//            print(dataArray[0].value(forKey: "missionName"))
//            print(dataArray[0].value(forKey: "pt"))
//            print(dataArray[0].value(forKey: "category"))
//        } catch {
//            print("ないよ")
//        }
//    }
    
    func makeRawData() {
        //バフされたptの初期化: Settingバフ
        if isBuffApplicated {
            let buffedCategory = buffArray.map{$0.category}
            for i in 0..<missionLists.count {
                if buffedCategory.contains(missionLists[i].listName) {
                    let index = buffedCategory.firstIndex(of: missionLists[i].listName)
                    let debuffedMissionList = missionLists[i].missionList.map{($0.mission, Int("\(Decimal($0.pt) / (Decimal(string: self.buffArray[index!].magnification)! * 10) * 10)")!)}
                    missionLists[i].missionList = debuffedMissionList
                }
            }
        }

    }
    
    func enchantData() {
        //Settingバフ
        if isBuffApplicated {
            let buffedCategory = buffArray.map{$0.category}
            for i in 0..<missionLists.count {
                if buffedCategory.contains(missionLists[i].listName) {
                    let index = buffedCategory.firstIndex(of: missionLists[i].listName)
//                    let intMag = buffArray[index!].magnification * 100.0
                    let buffedMissionList = missionLists[i].missionList.map{($0.mission, Int("\(Decimal($0.pt) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!)}
                    missionLists[i].missionList = buffedMissionList
                }
            }
        }
    }

    //MARK: - StoryBoard
    @IBOutlet weak var pointLabel: UIBarLabel!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - UI部品
    //ミッションを追加: alertで入力
    @objc func plusButtonTapped(_ sender: UIBarButtonItem){
        
        let alert = UIAlertController(title: "Todoの追加", message: "ToDo名と報酬ptを入力", preferredStyle: .alert)
        
        alert.addTextField { (mission: UITextField) -> Void in
            mission.placeholder = "Mission Name"
        }
        alert.addTextField { (pt: UITextField) -> Void in
            pt.placeholder = "Points"
        }
        alert.addTextField { (section: UITextField) -> Void in
            section.placeholder = "Section"
        }
        
        // missionLists末尾にセクション追加用要素を追加
        missionLists.append((missionList: [], listName: "新しいカテゴリを追加"))
        
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
            let missionTf = alert.textFields![0]
            let ptTf = alert.textFields![1]
            let sectionTf = alert.textFields![2]
            
            if let missionText = missionTf.text, let ptText = ptTf.text, let categoryText = sectionTf.text {
                if var ptInt = Int(ptText) {
                    // バフ適用中のカテゴリに追加する場合
                    if self.isBuffApplicated {
                        let buffedCategory = self.buffArray.map{$0.category}
                        for i in 0..<buffedCategory.count {
                            if categoryText == buffedCategory[i] {
                                let index = buffedCategory.firstIndex(of: categoryText)
//                                let intMag = self.buffArray[index!].magnification * 100.0
                                ptInt = Int("\(Decimal(ptInt) * (Decimal(string: self.buffArray[index!].magnification)! * 10) / 10)")!
                            }
                        }
                    }
                    // 既存のカテゴリに追加する場合 -> そのまま
                    if sectionTf.text != "新しいカテゴリを追加" {
                        self.missionLists.removeLast()
                        self.addMission(missionText, ptInt, self.selectedSectionIndex)
                    } else {
                    //カテゴリを新しく作成してから追加
                        self.createCategory(missionText, ptInt)
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
            self.missionLists.removeLast()
        })
        present(alert, animated: true, completion: nil)
    }
    
    //　アラート: エラー表示
    func showAlert(_ message: String){
        let alert : UIAlertController = UIAlertController(title: "警告", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    // アラート: カテゴリ作成
    func createCategory(_ mission: String, _ pt: Int) {
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
                self.missionLists.insert((missionList: [(mission, pt)], categoryText), at: self.selectedSectionIndex)
                self.missionLists.removeLast()
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
