//
//  JsonTestStrings.swift
//  gameSenseSports
//
//  Created by Ra on 11/17/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import Foundation


class JsonTestString: NSObject
{
    static func readJsonFile(fileName: String, bundle: Bundle) -> String
    {
        var fileString : String = ""
        let path = bundle.path(forResource: fileName, ofType: "txt")!
        do {
            fileString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        } catch {
            assert(true)
        }
        return fileString
    }
}
