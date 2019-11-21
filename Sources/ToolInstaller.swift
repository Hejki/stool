/*
 *  stool
 *
 *  Copyright (c) 2019 Hejki. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the  Software), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import CommandLineAPI
import Foundation
import Yams

/// Read tool config, build project and copy products
func cmdInstallTool() throws {
    do {
        let toolConfig = try ToolConfig.load(Path.current.appending(".stool.yml"))
        let buildConfig = toolConfig.build_config

        try CLI.run("swift build -c \(buildConfig)", executor: .interactive)
        try getProducts(buildConfig).forEach { try install($0, toolConfig.install_path) }
    } catch {
        CLI.println(error: "💩 \(error)")
    }
}

private struct BuildDescriptor: Decodable {
    let targets: [String: [String]]
}

private func getProducts(_ buildConfig: String) throws -> [String] {
    let buildDescriptionPath = Path.current.appending(".build/\(buildConfig).yaml")
    guard buildDescriptionPath.exist else {
        CLI.println(error: "💩 Cannot find build descriptor \(buildDescriptionPath, style: STR_FORMAT_PATH)")
        return []
    }

    let node = try YAMLDecoder().decode(BuildDescriptor.self, from: String(contentsOf: buildDescriptionPath))
    let executables = node.targets.filter { $0.key.hasSuffix(".exe") }

    if executables.count == 1 {
        let exe = executables.first!
        return [exe.value.first!]
    } else {
        var targets: [String: String] = ["🙊 All Targets": ""]

        for exe in executables {
            let product = exe.key.replacingOccurrences(of: "-\(buildConfig).exe", with: "")
            targets[product] = exe.value.first!
        }

        let product = CLI.choose("Select product: ", choices: targets)
        if product == "" {
            return executables.values.map { $0.first! }
        }

        return [product]
    }
}

private func install(_ productPath: String, _ installPath: String?) throws {
    let executable = try Path(productPath)
    guard executable.exist else {
        CLI.println(error: "💩 Executable path \(executable, style: .fgRed) not found.")
        return
    }

    if let installPath = installPath {
        let path = try Path(installPath)

        try executable.copy(to: path, overwrite: true)
        CLI.println("👍 \(executable.basenameWithoutExtension, style: .fgGreen, .bold) was installed to \(path, style: STR_FORMAT_PATH)")
    } else {
        CLI.println(error: "💩 Tool install path not defined. Please define install_path for \(executable.basenameWithoutExtension, style: .fgGreen, .bold) in your \(".stool", style: .fgYellow) config file.")
    }
}
