//
//  MissionViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class MissionViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    let userDefaults = UserDefaults.standard
    var missionList = [(mission: String, pt: Int)]()
    var exchangedPtHistory = Array<Int>()
    
    //リストは何行？
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return missionList.count
    }
    
    //セルの生成
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        cell.textLabel?.text = missionList[indexPath.row].mission
        cell.detailTextLabel?.text = String(missionList[indexPath.row].pt)
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // +とEditボタン追加
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        // リスト情報をmissionMemoryから読み込み
        if userDefaults.object(forKey: "missionMemory") != nil {
            if let dicList = userDefaults.object(forKey: "missionMemory") as? [[String: Any]] {
//                print(dicList)
                self.missionList = dicList.map{(mission: $0["mission"] as! String, pt: $0["pt"] as! Int)}
//                print(missionList)
            }
        } else {
            //リストが空欄の場合、テスト用Missionを追加
            missionList.append(("ポイントを100獲得", 100))
            missionList.append(("ポイントを50獲得", 50))
            tableView.reloadData()
        }
        
        //編集中でもセルを選択できるようにする
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 残りptとチケット数を取得
        let setting = UserDefaults.standard
        let presentPoint: Int = setting.integer(forKey: "storePoints")
        pointLabel.text = String(presentPoint)
        let presentTickets: Int = setting.integer(forKey: "storeTickets")
        ticketLabel.text = String(presentTickets)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //メイン画面vcにexchangedPtHistoryを渡す
        let nvc = self.navigationController!
        let vc = nvc.viewControllers[0] as! ViewController
        for element in exchangedPtHistory {
            vc.gotPointArray.append(element)
//            print(element)
        }
        //ptHistoryの初期化
        exchangedPtHistory.removeAll()
//        print("History Cleared")
        //リスト情報の保存
//        print(missionList)
        let convertedList: [[String: Any]] = missionList.map{["mission": $0.mission, "pt": $0.pt]}
//        print(convertedList)
        userDefaults.set(convertedList, forKey: "missionMemory")

    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var ticketLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    //Editタップ時編集モードへ
    override func setEditing(_ editing: Bool, animated: Bool) {
        super .setEditing(editing, animated: true)
        self.tableView.setEditing(editing, animated: true)
    }
    
    //全セルが削除対象
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //セル削除時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        missionList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
    }
    
    //ミッションを追加: alertで入力
    @objc func plusButtonTapped(_ sender: UIBarButtonItem){
        let alert = UIAlertController(title: "Todoの追加", message: "ToDo名と報酬ptを入力", preferredStyle: .alert)
        alert.addTextField { (mission: UITextField) -> Void in
            mission.placeholder = "Mission Name"
        }
        alert.addTextField { (pt: UITextField) -> Void in
            pt.placeholder = "Points"
        }
        var alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            let missionTf = alert.textFields![0]
            let ptTf = alert.textFields![1]
            if let missionText = missionTf.text, let ptText = ptTf.text {
                if let ptInt = Int(ptText) {
                    self.addMission(missionText, ptInt)
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
    
    //ミッションを追加: リストに追加
    func addMission(_ mission:String, _ pt:Int){
        // missionListに追加
        missionList.append((mission, pt))
        // TableViewに追加
        tableView.reloadData()
    }
    
    //エラー表示
    func showAlert(_ message: String){
        let alert : UIAlertController = UIAlertController(title: "警告", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    // セルをタップでポイント獲得
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tableView.isEditing {
            let setting = UserDefaults.standard
            var presentPoint: Int = setting.integer(forKey: "storePoints")
            let missionPoint: Int = missionList[indexPath.row].pt
            presentPoint += missionPoint
            setting.set(presentPoint, forKey: "storePoints")
            setting.synchronize()
            pointLabel.text = String(presentPoint)
            exchangedPtHistory.append(missionPoint)
        } else {
            // 編集モード時にタップしたらミッション名やポイントを変更できるようにする
            print("editing now")
        }
        
    }
    
    
}
