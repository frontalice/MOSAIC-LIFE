//
//  PptmManageViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/12/12.
//

import UIKit

class PptmManageViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    @IBOutlet weak var pptmTF: UITextField!
    @IBOutlet weak var passiveTable: UITableView!
    @IBOutlet weak var depassiveTable: UITableView!
    
    var pptMultiplier : Double = 1.05
    var passiveList : [(name: String, val: Double, state: Bool)] = [("テスト" , 0.01, false)]
    var depassiveList : [(name: String, val: Double, state: Bool)] = [("テスト" , 0.01, false)]
    
    //MARK: - TableViewDelegate
    
    // PrototypeCell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        
        var content = cell.defaultContentConfiguration()
        
        if tableView == passiveTable {
            content.text = passiveList[indexPath.row].name
            content.secondaryText = "+" + String(passiveList[indexPath.row].val)
            if (passiveList[indexPath.row].state) {
                cell.accessoryType = .checkmark
//                passiveTable.selectRow(at: IndexPath(row: indexPath.row, section: 0), animated: false, scrollPosition: .none)
            }
        } else {
            content.text = depassiveList[indexPath.row].name
            content.secondaryText = "-" + String(depassiveList[indexPath.row].val)
            if (depassiveList[indexPath.row].state) {
                cell.accessoryType = .checkmark
//                depassiveTable.selectRow(at: IndexPath(row: indexPath.row, section: 0), animated: false, scrollPosition: .none)
            }
        }
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == passiveTable {
            return passiveList.count
        } else {
            return depassiveList.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == passiveTable {
            return "Passive List"
        } else {
            return "DePassive List"
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super .setEditing(editing, animated: true)
        self.passiveTable.setEditing(editing, animated: true)
        self.depassiveTable.setEditing(editing, animated: true)
        passiveTable.reloadData()
        depassiveTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == passiveTable {
            passiveList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            savetuple(passiveList,"passiveList")
            passiveTable.reloadData()
        } else {
            depassiveList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            savetuple(depassiveList,"depassiveList")
            depassiveTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if tableView == passiveTable {
            let targetData = passiveList[sourceIndexPath.row]
            passiveList.remove(at: sourceIndexPath.row)
            passiveList.insert(targetData, at: destinationIndexPath.row)
            savetuple(passiveList,"passiveList")
            passiveTable.reloadData()
        } else {
            let targetData = depassiveList[sourceIndexPath.row]
            depassiveList.remove(at: sourceIndexPath.row)
            depassiveList.insert(targetData, at: destinationIndexPath.row)
            savetuple(depassiveList,"depassiveList")
            depassiveTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        if tableView == passiveTable {
            if !passiveTable.isEditing {
//                let dn1 = NSDecimalNumber(value: pptMultiplier)
//                let dn2 = NSDecimalNumber(value: passiveList[indexPath.row].val)
//                pptMultiplier = round(Double(truncating: dn1.adding(dn2)) * 100) / 100
                pptMultiplier = round((pptMultiplier + passiveList[indexPath.row].val) * 100) / 100
                pptmTF.text = String(pptMultiplier)
                UserDefaults.standard.set(pptMultiplier, forKey: "pptMultiplier")
                passiveList[indexPath.row].state = true
                savetuple(passiveList, "passiveList")
            } else {
                let alert = UIAlertController(title: "パッシブ名の編集", message: nil, preferredStyle: .alert)
                alert.addTextField { (name: UITextField) -> Void in
                    name.placeholder = "Passive Name"
                    name.text = self.passiveList[indexPath.row].name
                }
                alert.addTextField { (val: UITextField) -> Void in
                    val.placeholder = "Multiplier"
                    val.text = String(self.passiveList[indexPath.row].val)
                }
                let alertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                    let nameStr = alert.textFields![0].text
                    let valStr = alert.textFields![1].text
                    if let valDbl = Double(valStr!) {
                        self.passiveList[indexPath.row].name = nameStr!
                        self.passiveList[indexPath.row].val = valDbl
                        self.savetuple(self.passiveList, "passiveList")
                        self.passiveTable.reloadData()
                    } else {
                        self.showAlert("不正な値です")
                    }
                }
                alert.addAction(alertAction)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        } else {
            if !depassiveTable.isEditing {
                // pptMultiplier -= val
                if round((pptMultiplier - depassiveList[indexPath.row].val) * 100) / 100 >= 1.00 {
//                    let dn1 = NSDecimalNumber(value: pptMultiplier)
//                    let dn2 = NSDecimalNumber(value: depassiveList[indexPath.row].val)
//                    pptMultiplier = round(Double(truncating: dn1.subtracting(dn2)) * 100) / 100
                    pptMultiplier = round((pptMultiplier - depassiveList[indexPath.row].val) * 100) / 100
                    pptmTF.text = String(pptMultiplier)
                    UserDefaults.standard.set(pptMultiplier, forKey: "pptMultiplier")
                    depassiveList[indexPath.row].state = true
                    savetuple(depassiveList, "depassiveList")
                } else {
                    let cell = tableView.cellForRow(at: indexPath)
                    cell?.accessoryType = .none
                    depassiveTable.deselectRow(at: indexPath, animated: true)
                }
            } else {
                let alert = UIAlertController(title: "パッシブ名の編集", message: nil, preferredStyle: .alert)
                alert.addTextField { (name: UITextField) -> Void in
                    name.placeholder = "DePassive Name"
                    name.text = self.depassiveList[indexPath.row].name
                }
                alert.addTextField { (val: UITextField) -> Void in
                    val.placeholder = "Multiplier"
                    val.text = String(self.depassiveList[indexPath.row].val)
                }
                let alertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                    let nameStr = alert.textFields![0].text
                    let valStr = alert.textFields![1].text
                    if let valDbl = Double(valStr!) {
                        self.depassiveList[indexPath.row].name = nameStr!
                        self.depassiveList[indexPath.row].val = valDbl
                        self.savetuple(self.depassiveList, "depassiveList")
                        self.depassiveTable.reloadData()
                    } else {
                        self.showAlert("不正な値です")
                    }
                }
                alert.addAction(alertAction)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
        
        //didSelectRowAtと逆の処理
        if tableView == passiveTable {
            if !passiveTable.isEditing {
                // pptMultiplier -= val
                if round((pptMultiplier - passiveList[indexPath.row].val) * 100) / 100 >= 1.00 {
//                    let dn1 = NSDecimalNumber(value: pptMultiplier)
//                    let dn2 = NSDecimalNumber(value: passiveList[indexPath.row].val)
//                    pptMultiplier = round(Double(truncating: dn1.subtracting(dn2)) * 100) / 100
                    pptMultiplier = round((pptMultiplier - passiveList[indexPath.row].val) * 100) / 100
                    pptmTF.text = String(pptMultiplier)
                    UserDefaults.standard.set(pptMultiplier, forKey: "pptMultiplier")
                    passiveList[indexPath.row].state = false
                    savetuple(passiveList, "passiveList")
                } else {
                    let cell = tableView.cellForRow(at: indexPath)
                    cell?.accessoryType = .none
                    passiveTable.deselectRow(at: indexPath, animated: true)
                }
            } else {
                let alert = UIAlertController(title: "パッシブ名の編集", message: nil, preferredStyle: .alert)
                alert.addTextField { (name: UITextField) -> Void in
                    name.placeholder = "Passive Name"
                    name.text = self.passiveList[indexPath.row].name
                }
                alert.addTextField { (val: UITextField) -> Void in
                    val.placeholder = "Multiplier"
                    val.text = String(self.passiveList[indexPath.row].val)
                }
                let alertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                    let nameStr = alert.textFields![0].text
                    let valStr = alert.textFields![1].text
                    if let valDbl = Double(valStr!) {
                        self.passiveList[indexPath.row].name = nameStr!
                        self.passiveList[indexPath.row].val = valDbl
                        self.savetuple(self.passiveList, "passiveList")
                        self.passiveTable.reloadData()
                    } else {
                        self.showAlert("不正な値です")
                    }
                }
                alert.addAction(alertAction)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        } else {
            if !depassiveTable.isEditing {
                // pptMultiplier += val
//                let dn1 = NSDecimalNumber(value: pptMultiplier)
//                let dn2 = NSDecimalNumber(value: depassiveList[indexPath.row].val)
//                pptMultiplier = round(Double(truncating: dn1.adding(dn2)) * 100) / 100
                pptMultiplier = round((pptMultiplier + depassiveList[indexPath.row].val) * 100) / 100
                pptmTF.text = String(pptMultiplier)
                UserDefaults.standard.set(pptMultiplier, forKey: "pptMultiplier")
                depassiveList[indexPath.row].state = false
                savetuple(depassiveList, "depassiveList")
            } else {
                let alert = UIAlertController(title: "パッシブ名の編集", message: nil, preferredStyle: .alert)
                alert.addTextField { (name: UITextField) -> Void in
                    name.placeholder = "DePassive Name"
                    name.text = self.depassiveList[indexPath.row].name
                }
                alert.addTextField { (val: UITextField) -> Void in
                    val.placeholder = "Multiplier"
                    val.text = String(self.depassiveList[indexPath.row].val)
                }
                let alertAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in
                    let nameStr = alert.textFields![0].text
                    let valStr = alert.textFields![1].text
                    if let valDbl = Double(valStr!) {
                        self.depassiveList[indexPath.row].name = nameStr!
                        self.depassiveList[indexPath.row].val = valDbl
                        self.savetuple(self.depassiveList, "depassiveList")
                        self.depassiveTable.reloadData()
                    } else {
                        self.showAlert("不正な値です")
                    }
                }
                alert.addAction(alertAction)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
        
//        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Other Delegates
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let m = Double(pptmTF.text!) {
            print(m)
            pptMultiplier = m
            UserDefaults.standard.set(m, forKey: "pptMultiplier")
        }
        return true
    }
    
    // MARK: - functions
    
    @objc func plusButtonTapped(_ sender: UIBarButtonItem){
        let alert = UIAlertController(title: "パッシブの追加", message: nil, preferredStyle: .alert)
        alert.addTextField { (name: UITextField) -> Void in
            name.placeholder = "Passive/DePassive Name"
        }
        alert.addTextField { (val: UITextField) -> Void in
            val.placeholder = "Multiplier"
            val.text = "0.01"
        }
        
        let addPassive = UIAlertAction(title: "パッシブへ", style: .default) { (action: UIAlertAction) -> Void in
            let nameStr = alert.textFields![0].text
            let valStr = alert.textFields![1].text
            if let valDbl = Double(valStr!) {
                self.passiveList.append((nameStr!,valDbl,false))
                self.savetuple(self.passiveList, "passiveList")
                self.passiveTable.reloadData()
                self.reSelectCells()
            } else {
                self.showAlert("不正な値です")
            }
        }
        let addDePassive = UIAlertAction(title: "デパッシブへ", style: .default) { (action: UIAlertAction) -> Void in
            let nameStr = alert.textFields![0].text
            let valStr = alert.textFields![1].text
            if let valDbl = Double(valStr!) {
                self.depassiveList.append((nameStr!,valDbl,false))
                self.savetuple(self.depassiveList, "depassiveList")
                self.depassiveTable.reloadData()
                self.reSelectCells()
            } else {
                self.showAlert("不正な値です")
            }
        }
        alert.addAction(addPassive)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(addDePassive)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func whenPptmTFEdited(_ sender: Any) {
        if let m = Double(pptmTF.text!) {
            UserDefaults.standard.set(m, forKey: "pptMultiplier")
        }
    }
    
    func reSelectCells() {
        for i in 0..<passiveList.count {
            if passiveList[i].state {
                passiveTable.selectRow(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .none)
            }
        }
        for i in 0..<depassiveList.count {
            if depassiveList[i].state {
                depassiveTable.selectRow(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }
    
    func showAlert(_ message: String){
        let alert : UIAlertController = UIAlertController(title: "警告", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    // MARK: - Manage Tuple
    
    func savetuple(_ list: [(name: String, val: Double, state: Bool)], _ st_list: String){
        let convertedList: [[String : Any]] = list.map {
            ["name": $0.name, "val": $0.val, "state": $0.state]
        }
        UserDefaults.standard.set(convertedList, forKey: st_list)
    }
    
    func loadtuple(_ list: String) -> [(String, Double, Bool)]{
        if let dicList = UserDefaults.standard.object(forKey: list) as? [[String : Any]] {
            let loadedList = dicList.map{
                (name: $0["name"] as! String, val: $0["val"] as! Double, state: $0["state"] as! Bool)
            }
            return loadedList
        } else {
            return [("ロード失敗" , 0.01, false)]
        }
    }
    
    // MARK: - ライフサイクル
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pptmTF.delegate = self
        
        let addButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(self.plusButtonTapped(_:)))
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        
        if #available(iOS 15, *) {
            passiveTable.sectionHeaderTopPadding = 0.0
            depassiveTable.sectionHeaderTopPadding = 0.0
        }
        
        if UserDefaults.standard.object(forKey: "passiveList") == nil {
            savetuple(passiveList, "passiveList")
            savetuple(depassiveList, "depassiveList")
        }
        
//        UserDefaults.standard.register(defaults: [
//            "passiveList" : [("テスト2" , Double(0.01))],
//            "depassiveList" : [("テスト2" , Double(0.01))]
//        ])
        
        passiveList = loadtuple("passiveList")
        depassiveList = loadtuple("depassiveList")
        
        let isDayChanged = UserDefaults.standard.bool(forKey: "isDayChanged")
        if isDayChanged {
            for i in 1..<passiveList.count {
                passiveList[i].state = false
            }
            for i in 0..<depassiveList.count {
                depassiveList[i].state = false
            }
            savetuple(passiveList, "passiveList")
            savetuple(depassiveList, "depassiveList")
            UserDefaults.standard.set(false, forKey: "isDayChanged")
        }
        
        passiveTable.reloadData()
        depassiveTable.reloadData()
        
        passiveTable.allowsSelectionDuringEditing = true
        passiveTable.allowsMultipleSelection = true
        depassiveTable.allowsSelectionDuringEditing = true
        depassiveTable.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pptMultiplier = UserDefaults.standard.double(forKey: "pptMultiplier")
        pptmTF.text = String(pptMultiplier)
        
        reSelectCells()
    }
}
