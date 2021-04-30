//
//  MissionViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class MissionViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: - 保存データ関連
    
    let userDefaults = UserDefaults.standard
    var missionLists: [(missionList: [(mission: String, pt: Int)], listName: String)] = [([("ポイントを獲得", 100)],"TestSection")]
//    var missionList = [(mission: String, pt: Int)]()
    var exchangedPtHistory = Array<(item:String, pt:Int)>()
    
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
    }
    
    //移動できるセル: 全部
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //セル移動時の処理
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let targetCell = missionLists[sourceIndexPath.section].missionList[sourceIndexPath.row]
        missionLists[sourceIndexPath.section].missionList.remove(at: sourceIndexPath.row)
        missionLists[sourceIndexPath.section].missionList.insert(targetCell, at: destinationIndexPath.row)
    }
    
    //セル移動の制限: とりあえず同セクション間での移動のみに留める
    /*
     セルを動かしてるとき、
     移動中セルのセクションとその真下のセルのセクションが一致している場合は空きセルの場所がproposedDestinationIndexPathになり、
     セクションが一致してない場合は空きセルの場所は変化しない（sourceIndexPathのまま）、的な？
    */
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        return sourceIndexPath
    }
    
    // isEditing = false: セルをタップでポイント獲得
    // isEditing = true:  既存セルの編集
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tableView.isEditing {
            let setting = UserDefaults.standard
            var presentPoint: Int = setting.integer(forKey: "storePoints")
            let missionItem: String = missionLists[indexPath.section].missionList[indexPath.row].mission
            let missionPoint: Int = missionLists[indexPath.section].missionList[indexPath.row].pt
            presentPoint += missionPoint
            setting.set(presentPoint, forKey: "storePoints")
            setting.synchronize()
            pointLabel.text = String(presentPoint)
            exchangedPtHistory.append((missionItem,missionPoint))
        } else {
            // 編集モード時にタップしたらミッション名やポイントを変更できるようにする
//            print("editing now")
            let alert = UIAlertController(title: "Todoの編集", message: "ToDo名と報酬ptの編集", preferredStyle: .alert)
            alert.addTextField { (mission: UITextField) -> Void in
                mission.placeholder = "Mission Name"
                mission.text = self.missionLists[indexPath.section].missionList[indexPath.row].mission
            }
            alert.addTextField { (pt: UITextField) -> Void in
                pt.placeholder = "Points"
                pt.text = String(self.missionLists[indexPath.section].missionList[indexPath.row].pt)
            }
            var alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                let missionTf = alert.textFields![0]
                let ptTf = alert.textFields![1]
                if let missionText = missionTf.text, let ptText = ptTf.text {
                    if let ptInt = Int(ptText) {
                        self.missionLists[indexPath.section].missionList[indexPath.row].mission = missionText
                        self.missionLists[indexPath.section].missionList[indexPath.row].pt = ptInt
                        self.tableView.reloadData()
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
    }
    
    //MARK: - PickerView関連
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
        
        // +とEditボタン追加
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
//        let sortButton: UIBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(self.sortButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        // リスト情報をmissionMemoryから読み込み
        let categoryCount: Int = userDefaults.integer(forKey: "categoryCount")
        print("CategoryCount: \(categoryCount)")
        for i in 0..<categoryCount {
            if userDefaults.object(forKey: "missionMemory\(String(i))") != nil {
                if let dicList = userDefaults.object(forKey: "missionMemory\(String(i))") as? [[String: Any]] {
    //                print(dicList)
                    // 初期化したmissionListsにはmissionLists[1]以降が無いので都度追加
                    if i > 0 {
                        self.missionLists.append((missionList: [], listName: ""))
                    }
                    self.missionLists[i].missionList = dicList.map{(mission: $0["mission"] as! String, pt: $0["pt"] as! Int)}
                    if let listName = userDefaults.string(forKey: "categoryName\(String(i))") {
                        self.missionLists[i].listName = listName
                    } else {
                        continue
                    }
    //                print(missionList)
                }
            } else {
                //保存データが無い場合、アラート表示
                showAlert("データの読み込みに失敗しています")
            }
        }
        
        tableView.reloadData()
        
        //編集中でもセルを選択できるようにする
        self.tableView.allowsSelectionDuringEditing = true
        
        // 残りptとチケット数を取得
        let setting = UserDefaults.standard
        let presentPoint: Int = setting.integer(forKey: "storePoints")
        pointLabel.text = String(presentPoint)
        let presentTickets: Int = setting.integer(forKey: "storeTickets")
        ticketLabel.text = String(presentTickets)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //メイン画面vcにexchangedPtHistoryを渡す
        let nvc = self.navigationController!
        let vc = nvc.viewControllers[0] as! ViewController
        for i in 0..<exchangedPtHistory.count {
            vc.gotPointArray.append(exchangedPtHistory[i])
//            print(element)
        }
        //ptHistoryの初期化
        exchangedPtHistory.removeAll()
//        print("History Cleared")
        //リスト情報の保存
        for i in 0..<missionLists.count {
//            print(missionList)
            let convertedList: [[String: Any]] = missionLists[i].missionList.map{["mission": $0.mission, "pt": $0.pt]}
//            print(convertedList)
            userDefaults.set(convertedList, forKey: "missionMemory\(String(i))")
            userDefaults.set(missionLists[i].listName, forKey: "categoryName\(String(i))")
            print(userDefaults.dictionaryRepresentation().filter { $0.key.hasPrefix("missionMemory") })
            print("----------------------\n")
        }
        userDefaults.set(missionLists.count, forKey: "categoryCount")
    }

    //MARK: - StoryBoard
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var ticketLabel: UILabel!
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
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(0, inComponent: 0, animated: true)

        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonOnToolBarTapped(_:)))
        toolbar.setItems([doneButton], animated: true)
        toolbar.sizeToFit()

        //pickerViewに関する処理: 実装
        alert.textFields![2].inputAccessoryView = toolbar
        alert.textFields![2].inputView = pickerView
        
        //OKボタンを押した時の挙動
        let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            let missionTf = alert.textFields![0]
            let ptTf = alert.textFields![1]
            let sectionTf = alert.textFields![2]
            
            if let missionText = missionTf.text, let ptText = ptTf.text {
                if let ptInt = Int(ptText) {
                    if sectionTf.text != "新しいカテゴリを追加" {
                        //既存のカテゴリに追加 -> そのまま
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
    
    // ソートボタン: 降順で並び替え
//    @objc func sortButtonTapped(_ sender: UIBarButtonItem){
//        for i in 0..<missionLists.count {
//            missionLists[i].missionList.sort{(A,B) -> Bool in
//                return A.pt > B.pt
//            }
//        }
//        self.tableView.reloadData()
//    }
    
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
        
        let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            if let categoryText = alert.textFields![0].text {
                self.missionLists.removeLast()
                self.missionLists.append((missionList: [(mission, pt)], categoryText))
                self.tableView.reloadData()
            } else {
                self.showAlert("なんか書いてくれ")
            }
        }
        
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
}
