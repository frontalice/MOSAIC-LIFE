//
//  ShopViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ShopViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    let userDefaults = UserDefaults.standard
    var shopList = [(item: String, pt: Int)]()
    var consumedPtHistory = Array<Int>()
    
    // リストは何行？
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopList.count
    }
    
    // セルの生成
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        cell.textLabel?.text = shopList[indexPath.row].item
        cell.detailTextLabel?.text = String(shopList[indexPath.row].pt)
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // +とEditボタン追加
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        // リスト情報をshopMemoryから読み込み
        if userDefaults.object(forKey: "shopMemory") != nil {
            if let dicList = userDefaults.object(forKey: "shopMemory") as? [[String: Any]] {
//                print(dicList)
                self.shopList = dicList.map{(item: $0["item"] as! String, pt: $0["pt"] as! Int)}
//                print(shopList)
            }
        } else {
            //リストが空欄の場合、テスト用itemを追加
            shopList.append(("ポイントを100消費", 100))
            shopList.append(("ポイントを50消費", 50))
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
        // メイン画面vcにconsumedPtHistoryを渡す
        let nvc = self.navigationController!
        let vc = nvc.viewControllers[0] as! ViewController
        for element in consumedPtHistory {
            vc.usedPointArray.append(element)
//            print(element)
        }
        //ptHistoryの初期化
        consumedPtHistory.removeAll()
        //リスト情報の保存
        let convertedList: [[String: Any]] = shopList.map{["item": $0.item, "pt": $0.pt]}
        userDefaults.set(convertedList, forKey: "shopMemory")
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
        shopList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
    }
    
    //アイテムを追加: alertで入力
    @objc func plusButtonTapped(_ sender: UIBarButtonItem){
        let alert = UIAlertController(title: "Itemの追加", message: "Item名と必要ptを入力", preferredStyle: .alert)
        alert.addTextField { (item: UITextField) -> Void in
            item.placeholder = "Item Name"
        }
        alert.addTextField { (pt: UITextField) -> Void in
            pt.placeholder = "Points"
        }
        var alertAction : UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
            let itemTf = alert.textFields![0]
            let ptTf = alert.textFields![1]
            if let itemText = itemTf.text, let ptText = ptTf.text {
                if let ptInt = Int(ptText) {
                    self.addItem(itemText, ptInt)
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
    
    //アイテムを追加: リストに追加
    func addItem(_ item:String, _ pt:Int){
        // shopListに追加
        shopList.append((item, pt))
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
    
    //セルをタップでポイント消費
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tableView.isEditing{
            let setting = UserDefaults.standard
            var presentPoint: Int = setting.integer(forKey: "storePoints")
            let consumePoint: Int = shopList[indexPath.row].pt
            if presentPoint - consumePoint < 0 {
                return
            }
            presentPoint -= consumePoint
            setting.set(presentPoint, forKey: "storePoints")
            setting.synchronize()
            pointLabel.text = String(presentPoint)
            consumedPtHistory.append(consumePoint)
        } else {
            // 編集モード時にタップしたらミッション名やポイントを変更できるようにする
            print("editing now")
        }
        
    }

}
