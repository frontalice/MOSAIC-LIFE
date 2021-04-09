//
//  ShopViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ShopViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    var shopList : [String:Int] = ["ポイントを50消費":50, "ポイントを100消費":100]
    var pointArray = Array<Int>()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        cell.textLabel?.text = Array(shopList.keys)[indexPath.row]
        cell.detailTextLabel?.text = String(Array(shopList.values)[indexPath.row])
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let setting = UserDefaults.standard
        let presentPoint: Int = setting.integer(forKey: "storePoints")
        pointLabel.text = String(presentPoint)
        let presentTickets: Int = setting.integer(forKey: "storeTickets")
        ticketLabel.text = String(presentTickets)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let nvc = self.navigationController!
        let vc = nvc.viewControllers[0] as! ViewController
        for element in pointArray {
            vc.usedPointArray.append(element)
            print(element)
        }
        pointArray.removeAll()
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = UserDefaults.standard
        var presentPoint: Int = setting.integer(forKey: "storePoints")
        let consumePoint: Int = Array(shopList.values)[indexPath.row]
        if presentPoint - consumePoint < 0 {
            return
        }
        presentPoint -= consumePoint
        setting.set(presentPoint, forKey: "storePoints")
        setting.synchronize()
        pointLabel.text = String(presentPoint)
        pointArray.append(consumePoint)
    }

}
