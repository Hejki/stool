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

/// Read tool config, build project and copy products
func cmdInstallTool() throws {
    let toolConfig = try ToolConfig.load(Path.current.appending(".stool"))
    let buildConfig = toolConfig.build_config

    try CLI.run("swift build -c \(buildConfig)", executor: .interactive)
//    if build.compile() {
//        CLI.println(error: "💩 Tool build failed!".styled(.bright(.fgRed)))
//        return
//    }

    if let product = toolConfig.product {
        try InstallProduct(config: buildConfig, product: product, installPath: toolConfig.install_path).install()
        return
    }

    for product in toolConfig.products ?? [] {
        try InstallProduct(config: buildConfig, product: product.name, installPath: product.install_path).install()
    }
}

private struct InstallProduct {
    let config: String
    let product: String
    let installPath: String?

    func install() throws {
        let executable = Path.current + ".build" + config + product
        guard executable.exist else {
            CLI.println(error: "💩 Executable path \(executable, style: .fgRed) not found.")
            return
        }

        if let installPath = installPath {
            let path = try Path(installPath)

            try executable.copy(to: path, overwrite: true)
            CLI.println("👍 '\(product, style: .fgGreen, .bold)' was installed to '\(path, style: STR_FORMAT_PATH)'")
        } else {
            CLI.println(error: "💩 Tool install path not defined. Please define install_path for \(product, style: .fgYellow) in your \(".stool", style: .fgYellow) config file.")
        }
    }
}
