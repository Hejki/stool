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

/// Type of stool configs
protocol SToolConfig: Decodable {}

extension SToolConfig {

    /// Load config from yaml file
    static func load(_ config: Path) throws -> Self {
        guard config.exist else {
            throw SToolError.configNotExist(config)
        }

        do {
            let yaml = try String(contentsOf: config)
            return try YAMLDecoder().decode(from: yaml)
        } catch {
            throw SToolError.configDecodeError(config, error)
        }
    }
}

enum SToolError: Error {
    case configNotExist(_ path: Path)
    case configDecodeError(_ path: Path, _ error: Error)
}

/// Main config file, placed in `~/.stool/config.yml`
struct MainConfig: SToolConfig, Encodable {
    let tools_directory: Path?
    let variables: [String: AnyCodable]
}

/// Concrete tool config `.stool.yml` define info for `install` action
struct ToolConfig: SToolConfig {
    let product: String?
    let install_path: String?
    let build_config: String
    let products: [Product]?

    init() {
        product = ""
        install_path = nil
        build_config = "release"
        products = nil
    }

    struct Product: Decodable {
        let name: String
        let install_path: String?
    }
}

/// Initialize main config
class SToolMainConfigInit {
    private var config: MainConfig?
    private let configPath: Path
    private var toolsDirectory: String = ""
    private var variables: [String: String] = [:]
    private var swiftEnvVersion: String?
    private var swiftFormatVersion: String?

    init(_ path: Path) {
        self.configPath = path
        self.swiftEnvVersion = try? CLI.run("swiftenv version").split(separator: " ").first.map(String.init)
        self.swiftFormatVersion = try? CLI.run("swiftformat --version")

        self.variables["swift_version"] = swiftEnvVersion ?? DEFAULT_SWIFT_VERSION
        self.variables["build_config"] = "release"
        self.variables["author"] = NSFullUserName()
    }

    func run() -> MainConfig {
        CLI.println("🏃‍♀️ \(STR_STOOL) initialization.")

        while config == nil {
            showQuestions()
            showConfirmation()
        }

        CLI.println("\n🖖 \(STR_STOOL) configured successfully.")
        CLI.println("Use \("stool init toolName", style: .bold, .fgGreen) to create a new tool.")
        CLI.println("Use \("stool install", style: .bold, .fgGreen) to build and install tool in current directory.")
        CLI.println("Use \("stool templates", style: .bold, .fgGreen) for manage project templates.")
        CLI.println("")
        return config!
    }

    /// Show questions
    private func showQuestions() {
        toolsDirectory = CLI.ask("Enter the default tools project directory location, empty if you don't want to set it.\n: ")

        let author = variables["author"]!
        variables["author"] = CLI.ask("Author name [\(author)]: ", options: .default(author))

        let swiftVersion = variables["swift_version"] ?? DEFAULT_SWIFT_VERSION
        variables["swift_version"] = CLI.ask("Default Swift version [\(swiftVersion)]: ", options: .default(swiftVersion))

        if swiftEnvVersion != nil {
            variables["use_swiftenv"] = CLI.ask("Use swiftenv [y]: ", type: Bool.self, options: .default(true)).description
        }

        if swiftFormatVersion != nil {
            variables["use_swiftformat"] = CLI.ask("Use swiftformat [y]: ", type: Bool.self, options: .default(true)).description
        }

        variables["build_config"] = CLI.choose("Choose default build config: ", choices: ["debug", "release"])
        variables["use_tests"] = CLI.ask("Include unit tests [y]: ", type: Bool.self, options: .default(true)).description
    }

    /// Show confirmation and then create config
    private func showConfirmation() {
        let toolsDirPath: Path? = (toolsDirectory != "" ? try! Path(toolsDirectory) : nil)
        CLI.println("\n🤷 Confirm \(STR_STOOL) configuration.")
        if let path = toolsDirPath {
            CLI.println("  tools_directory: \(path, style: .fgBlue)")
        } else {
            CLI.println("  tools_directory: \("not set", style: .fgBlue, .italic)")
        }
        CLI.println("  author:          \(variables["author"], style: .fgBlue)")
        CLI.println("  swift_version:   \(variables["swift_version"], style: .fgBlue)")
        if let swiftEnv = variables["use_swiftenv"] {
            CLI.println("  use_swiftenv:    \(swiftEnv, style: .fgBlue)")
        }
        if let swiftFormat = variables["use_swiftformat"] {
            CLI.println("  use_swiftenv:    \(swiftFormat, style: .fgBlue)")
        }
        CLI.println("  build_config:    \(variables["build_config"], style: .fgBlue)")
        CLI.println("  use_tests:       \(variables["build_config"], style: .fgBlue)")

        if CLI.ask("Is this ok? ") {
            self.config = MainConfig(tools_directory: toolsDirPath, variables: variables.mapValues { AnyCodable($0) })
            do {
                try configPath.parent.createDirectory()
                try configPath.touch().write(text: YAMLEncoder().encode(config))
            } catch {
                CLI.println(error: "💩 Cannot create \(STR_STOOL) config file '\(configPath, style: STR_FORMAT_PATH)'")
                abort()
            }
        }
    }
}
