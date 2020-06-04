//
//  Data.swift
//  Scanner
//
//  Created by Andy Zhang on 5/28/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import Foundation
import RealmSwift

class Data: Object{
    @objc dynamic var text: String = ""
    @objc dynamic var imageKey: String = ""
}
