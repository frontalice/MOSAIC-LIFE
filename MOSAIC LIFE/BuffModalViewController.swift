//
//  BuffModalViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/05/04.
//

import UIKit
import DropDown

class BuffModalViewController: UIViewController, UITextFieldDelegate {

    let dateFormatter = DateFormatter()
    let dropDown = DropDown()
    var missionCategoryArray = Array<String>()
    var shopCategoryArray = Array<String>()
    var buffArray: [(buffName: String, magnification: Float, category: String, date: Date)] = Array<(String, Float, String, Date)>()
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == magnificationLabel {
            let magCharas: String = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            if magCharas.count <= 4 {
                return true
            }
            return false
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        magnificationLabel.delegate = self
        
        //倍率入力用キーボードにdoneボタンを追加
        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonOnToolBarTapped(_:)))
        toolbar.setItems([doneButton], animated: true)
        toolbar.sizeToFit()
        magnificationLabel.inputAccessoryView = toolbar
        
        // カテゴリ名の取得
        let missionCategoryCount = UserDefaults.standard.integer(forKey: "categoryCount")
        for i in 0..<missionCategoryCount {
            missionCategoryArray.append(UserDefaults.standard.string(forKey: "categoryName\(String(i))")!)
        }
        
        let shopCategoryCount = UserDefaults.standard.integer(forKey: "categoryCount_shop")
        for i in 0..<shopCategoryCount {
            shopCategoryArray.append(UserDefaults.standard.string(forKey: "categoryName\(String(i))_shop")!)
        }
        
        // セグメントコントロールの初期化
        segmentedControl.selectedSegmentIndex = 0
        
        // DropDownの初期化
        initDropDown()
        
        //カテゴリラベルの初期化
        categoryLabel.text = missionCategoryArray[0]

        // Do any additional setup after loading the view.
//        datePicker.addTarget(self, action: #selector(writeLimitDate), for: .valueChanged)
        
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy年M月d日"
        dateLabel.text = dateFormatter.string(from: datePicker.date)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let dicList = UserDefaults.standard.object(forKey: "buffData") as? [[String : Any]] {
            self.buffArray = dicList.map{(buffName: $0["name"] as! String, magnification: $0["mag"] as! Float, category: $0["category"] as! String, date: $0["date"] as! Date)}
        }
    }
    
    func initDropDown(){
        dropDown.anchorView = categoryLabel
        if segmentedControl.selectedSegmentIndex == 0 {
            dropDown.dataSource = missionCategoryArray
        } else {
            dropDown.dataSource = shopCategoryArray
        }
        dropDown.direction = .bottom
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            categoryLabel.text = item
          }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

   
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var magnificationLabel: UITextField!
    @IBOutlet weak var categoryLabel: CustomUILabel!
    @IBOutlet weak var dateLabel: CustomUILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if nameLabel.text!.isEmpty == false && self.magnificationLabel.text!.isEmpty == false && categoryLabel.text!.isEmpty == false {
            if let decimal = Decimal(string: magnificationLabel.text!) {
                if decimal != 0 {
                    let buffedCategory = buffArray.map{$0.category}
                    if buffedCategory.contains(categoryLabel.text!) {
                        showAlert("既にバフが適用されてるカテゴリです")
                    } else {
                        // 保存処理: buffArray変数に保存
                        buffArray.append((nameLabel.text!, NSString(string: magnificationLabel.text!).floatValue, categoryLabel.text!, datePicker.date))
                        print("Done後: \(buffArray)")
                        
                        // 保存処理: buffArray -> UserDefaultsに保存
                        let convertedList: [[String: Any]] = buffArray.map{["name": $0.buffName, "mag": $0.magnification, "category": $0.category, "date": $0.date]}
                        UserDefaults.standard.set(convertedList, forKey: "buffData")
                        
                        // メイン画面のバフログに書き込み
                        let nc = self.presentingViewController as! UINavigationController
                        let mainVC = nc.viewControllers[0] as! ViewController
                        dateFormatter.dateFormat = "MM/dd"
                        let date = self.dateFormatter.string(from: self.datePicker.date)
                        mainVC.buffLog.text += "[\(date)] \"\(self.nameLabel.text!)\"が<\(self.categoryLabel.text!)>で発動中(x\(self.magnificationLabel.text!))\n"
                        
                        // モーダルを閉じる
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    showAlert("不正な入力です")
                }
            } else {
                showAlert("不正な入力です")
            }
        } else {
            showAlert("不正な入力です")
        }
//        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func segConChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            categoryLabel.text = missionCategoryArray[0]
        } else {
            categoryLabel.text = shopCategoryArray[0]
        }
        initDropDown()
    }
    
    @objc func doneButtonOnToolBarTapped(_ sender: UIBarButtonItem){
        magnificationLabel.endEditing(true)
    }
    
    @IBAction func showDropDown(_ sender: Any) {
        dropDown.show()
    }
    @IBAction func dateChanged(_ sender: Any) {
        dateLabel.text = dateFormatter.string(from: datePicker.date)
    }
    
    //　アラート: エラー表示
    func showAlert(_ message: String){
        let alert : UIAlertController = UIAlertController(title: "警告", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "はい", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
