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

import Commander
import CommandLineAPI
import Foundation
import Stencil

func cmdInitTool(
    template: String,
    quiet: Bool,
    variables: [String],
    name: String?
) throws {
    try ToolCreator(template, name, quiet, variables).run()
}

private struct ToolCreator {
    let templatePath: Path?
    let toolPath: Path
    let quiet: Bool
    let variables: [String]
    let stencil: Environment

    init(_ template: String?, _ toolName: String?, _ quiet: Bool, _ variables: [String]) throws {

        if let template = template {
            self.templatePath = Path.home + ".stool/templates" + template
        } else {
            self.templatePath = nil
        }

        self.toolPath = try Self.toolPath(forName: toolName, quiet)
        self.quiet = quiet
        self.variables = variables
        self.stencil = Environment(extensions: [SToolStencilExtension()])
    }

    func run() throws {

        if let path = templatePath, path.exist {
            try copyTemplates(from: path)
        } else {
            try TemplateManager(templatesDirectory: toolPath.parent)
                .installDefault(name: toolPath.basename, quietOverwrite: quiet)
        }

        let basename = toolPath.basename
        var templateContext: [String: Any] = [
            "currentDate": Date(),
            "name": basename,
            "target": basename
                .capitalized
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined(),
        ]

        // merge, don't overwrite name and target keys
        templateContext.merge(config.variables) { current, _ in current }

        variables.filter { $0.contains("=") }
            .map { $0.split(separator: "=", maxSplits: 2) }
            .forEach { templateContext[String($0.first!)] = String($0.last!) }

        templateContext = templateContext.mapValues { ($0 as? AnyCodable)?.value ?? $0 }

        try toolPath.children.includingHidden.forEach {
            try customize(path: $0, templateContext)
        }

        CLI.println("🙌 Tool \(basename, style: .fgGreen, .bold) was created at \(toolPath, style: .faint)")

        if !quiet {
            #if os(macOS)
            // Open XCode
            _ = try? CLI.run("open -b com.apple.dt.Xcode", toolPath.appending("Package.swift").path)
            #endif

            //TODO: Open new shell on tool location
            // try CLI.run("cd ", toolPath.path.quoted, executor: .interactive)
        }
    }

    /// Copy template directory content to tool path.
    private func copyTemplates(from path: Path) throws {
        try path.children.includingHidden.forEach {
            try $0.copy(to: toolPath)
        }
    }

    /**
     Customize text templates on path.
     Replace text placeholders in file/folder names and files content.
     */
    private func customize(path p: Path, _ context: [String: Any]) throws {
        var path = p
        let pathBasename = path.basename

        if pathBasename.contains("{") {
            let newName = try render(template: pathBasename, context)

            if newName == "" {
                try path.delete()
            } else {
                path = try path.rename(to: newName)
            }
        }

        try path.children.includingHidden.forEach { try customize(path: $0, context) }

        if path.type == .file {
            try render(template: try String(contentsOf: path), context)
                .write(to: path)
        }
    }

    /**
     Render text template.
     */
    private func render(template: String, _ context: [String: Any]) throws -> String {
        return try stencil.renderTemplate(string: template, context: context)
    }

    private static func toolPath(forName toolName: String?, _ quiet: Bool) throws -> Path {
        let toolPath: Path

        if let toolName = toolName, toolName.hasPrefix("/") {
            // absolute path use it
            toolPath = try Path(toolName)
        } else if let stoolRoot = config.tools_directory {
            // tools root path is defined, write tool dir to this path
            if toolName == nil, quiet {
                print("💩 Tool name must be specified if tools_directory is defined in global config. Add argument with tool name for `init` command.")
                throw ArgumentError.missingValue(argument: "name")
            }

            let definedToolName: String
            if toolName == nil, !quiet {
                definedToolName = CLI.ask(
                    "Tool name: ",
                    options: .notEmptyValidator("Tool name cannot be empty if tools_directory is defined in global config.")
                )
            } else {
                definedToolName = toolName!
            }

            toolPath = stoolRoot + definedToolName
        } else {
            // in other cases use current directory
            toolPath = Path.current.appending(toolName ?? "")
        }

        if quiet {
            return toolPath
        }

        let path = CLI.ask("Tool directory [\(toolPath)]: ", options: .default(toolPath))
        if path.exist && !path.children.isEmpty {
            if quiet {
                CLI.println(error: "💩 Tool directory \(path, style: STR_FORMAT_PATH) is already exist.")
                abort()
            }

            let remove = CLI.ask(
                "😮 Tool directory \(path, style: STR_FORMAT_PATH) already exist. Do you want to delete it? ",
                type: Bool.self
            )
            if remove {
                try path.delete(useTrash: true)
            } else {
                abort()
            }
        }
        return try path.createDirectory()
    }
}

private class SToolStencilExtension: Extension {

    override init() {
        super.init()
        registerFilter("format", filter: format)
    }

    private func format(value: Any?, arguments: [Any?]) throws -> Any? {
        guard let date = value as? Date else {
            return nil
        }

        guard let format = arguments.first as? String else {
            return nil
        }

        let formatter = DateFormatter()

        formatter.dateFormat = format
        return formatter.string(from: date)
    }

}
