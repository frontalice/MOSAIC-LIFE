//
//  BuffModalViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/05/04.
//

import UIKit
import DropDown

class BuffModalViewController: UIViewController {

    let dateFormatter = DateFormatter()
    let dropDown = DropDown()
    var missionCategoryArray = Array<String>()
    var shopCategoryArray = Array<String>()
    var buffArray: [(buffName: String, magnification: Float, category: String, date: Date)] = Array<(String, Float, String, Date)>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let missionCategoryCount = UserDefaults.standard.integer(forKey: "categoryCount")
        for i in 0..<missionCategoryCount {
            missionCategoryArray.append(UserDefaults.standard.string(forKey: "categoryName\(String(i))")!)
        }
        
        let shopCategoryCount = UserDefaults.standard.integer(forKey: "categoryCount_shop")
        for i in 0..<shopCategoryCount {
            shopCategoryArray.append(UserDefaults.standard.string(forKey: "categoryName\(String(i))_shop")!)
        }
        
        segmentedControl.selectedSegmentIndex = 0
        
        initDropDown()
        
        categoryLabel.text = missionCategoryArray[0]

        // Do any additional setup after loading the view.
//        datePicker.addTarget(self, action: #selector(writeLimitDate), for: .valueChanged)
        
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy年M月d日"
        dateLabel.text = dateFormatter.string(from: datePicker.date)
        
    }
    
    func initDropDown(){
        dropDown.anchorView = categoryLabel
        if segmentedControl.selectedSegmentIndex == 0 {
            dropDown.dataSource = missionCategoryArray
        } else {
            dropDown.dataSource = shopCategoryArray
        }
        print("対象の配列: \(dropDown.dataSource)")
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
        if self.magnificationLabel.text!.isEmpty == false {
            if nameLabel.text!.isEmpty == false && categoryLabel.text!.isEmpty == false {
                buffArray.append((nameLabel.text!, NSString(string: magnificationLabel.text!).floatValue, categoryLabel.text!, datePicker.date))
                let convertedList: [[String: Any]] = buffArray.map{["name": $0.buffName, "mag": $0.magnification, "category": $0.category, "date": $0.date]}
                UserDefaults.standard.set(convertedList, forKey: "buffData")
                print(UserDefaults.standard.object(forKey: "buffData")!)
                
                let nc = self.presentingViewController as! UINavigationController
                print(nc.viewControllers[0])
                let mainVC = nc.viewControllers[0] as! ViewController
                self.dateFormatter.dateFormat = "MM/dd"
                let date = self.dateFormatter.string(from: self.datePicker.date)
                mainVC.buffLog.text = "[\(date)] \"\(self.nameLabel.text!)\"が<\(self.categoryLabel.text!)>で発動中(x\(magnificationLabel.text!))"
                
                self.dismiss(animated: true) {
//                    print(self.presentingViewController)
//                    let mainVC = self.presentingViewController as! ViewController
//                    self.dateFormatter.dateFormat = "MM/dd"
//                    let date = self.dateFormatter.string(from: self.datePicker.date)
//                    mainVC.buffLog.text = "[\(date)] 「\(self.nameLabel.text!)」が<\(self.categoryLabel.text!)>で発動中"
                }
            }
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
