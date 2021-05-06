//
//  BuffModalViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/05/04.
//

import UIKit

class BuffModalViewController: UIViewController {

    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        datePicker.addTarget(self, action: #selector(writeLimitDate), for: .valueChanged)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy年M月d日"
        dateLabel.text = dateFormatter.string(from: datePicker.date)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBOutlet weak var dateLabel: CustomUILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func dateChanged(_ sender: Any) {
        dateLabel.text = dateFormatter.string(from: datePicker.date)
    }
    
    
//    @objc func writeLimitDate(){
//        print()
//    }
}
