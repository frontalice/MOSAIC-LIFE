//
//  ViewController.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/03/22.
//

import UIKit

class ViewController: UIViewController {

    let settings = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        pointLabel.layer.borderWidth = 2.0
        pointLabel.layer.borderColor = UIColor.black.cgColor
        settings.register(defaults: ["storePoints":0, "storeTickets":0])
        pointLabel.text = String(roadPoints())
        ticketLabel.text = String(roadTickets())
    }

    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var ticketLabel: UILabel!
    
    func roadPoints() -> Int {
        let roadPoint : Int = settings.integer(forKey: "storePoints")
        return roadPoint
    }
    
    func roadTickets() -> Int {
        let roadTicket : Int =
            settings.integer(forKey: "storeTickets")
        return roadTicket
    }
}

