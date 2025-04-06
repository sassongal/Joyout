//
//  ScriptRunner.swift
//  Joyout
//
//  Created by Gal Sasson on 03/04/2025.
//

import Foundation

class ScriptRunner {
    static func runScript(named scriptName: String, args: [String] = []) {
        guard let scriptPath = Bundle.main.path(forResource: scriptName, ofType: "py", inDirectory: "Scripts") else {
            print("Script not found: \(scriptName)")
            return
        }

        let task = Process()
        task.launchPath = "/usr/bin/python3"  // או תעדכן בהתאם לגרסה
        task.arguments = [scriptPath] + args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("Script output: \(output)")
        }
    }
}
