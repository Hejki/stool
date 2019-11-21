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

struct TemplateManager {
    let templatesDirectory: Path

    init(templatesDirectory: Path = MAIN_CONFIG_PATH.parent.appending("templates")) {
        self.templatesDirectory = templatesDirectory
    }

    /**
     Downloads and copy template from url, or copy default template under new name.
     - *location* is valid url - download, unzip and copy
     - *location* is string - copy default template under new name
     - otherwise error
     */
    func install(_ location: String) throws {
        if let url = URL(string: location), url.scheme != nil {
            CLI.println(error: "🤬 Download templates from url is not implemented yet!")
        } else if !location.contains("/") {
            try installDefault(name: location, quietOverwrite: false)
        } else {
            CLI.println(error: "💩 Cannot create the new template!")
        }
    }

    /// Remove template.
    func remove(force: Bool, templateName: String) throws {
        let path = templatesDirectory.appending(templateName)

        guard path.exist else { return }

        if force {
            try path.delete()
        } else {
            let realyRemove = CLI.ask("Delete a template from \(path, style: STR_FORMAT_PATH)? ", type: Bool.self)

            if realyRemove {
                try path.delete(useTrash: true)
            }
        }
    }

    /// Copy default template to `templates/default`
    func installDefault() throws {
        try installDefault(name: "default", quietOverwrite: false)
    }

    /// Create default template in templates
    func installDefault(name dirName: String?, quietOverwrite: Bool) throws {
        let templateDir = templatesDirectory.appending(dirName)

        if templateDir.exist {
            let overwrite = (quietOverwrite ? true : CLI.ask("Overwrite template at path \(templateDir, style: STR_FORMAT_PATH)? ", type: Bool.self))

            if overwrite {
                try templateDir.delete(useTrash: true)
            } else {
                exit(0)
            }
        }

        try templateDir.createDirectory()
            .appending("Package.swift")
            .write(text: DefaultTemplate.packageTemplate)

        try templateDir.createDirectory("Sources")
            .appending("main.swift")
            .touch()
            .write(text: DefaultTemplate.main)

        try templateDir.appending(".stool.yml")
            .write(text: DefaultTemplate.stoolConfig)

        try templateDir.appending("{% if use_swiftenv %}.swift-version{% endif %}")
            .write(text: "{{ swift_version|default:\"\(DEFAULT_SWIFT_VERSION)\" }}")

        try templateDir.appending("{% if use_swiftformat %}.swiftformat{% endif %}")
            .write(text: DefaultTemplate.swiftformat)

        try templateDir.appending("LICENSE")
            .write(text: DefaultTemplate.license)

        let testsDir = try templateDir.createDirectory("{% if use_tests %}Tests{% endif %}")

        let toolTestDir = try testsDir.createDirectory("{{target}}Tests")
        try toolTestDir.touch("{{target}}Tests.swift").write(text: DefaultTemplate.exampleTest)

        if dirName != nil {
            CLI.println("👏 Default \(STR_STOOL) template was placed to \(templateDir, style: STR_FORMAT_PATH). You can change it as you like.")
        }
    }

    /// List all installed templates
    func listTemplates() throws {
        for template in templatesDirectory.children {
            CLI.println(template.basename)
        }
    }
}

private struct DefaultTemplate {
    static var packageTemplate = """
    // swift-tools-version:{{ swift_version|default:"\(DEFAULT_SWIFT_VERSION)" }}

    import PackageDescription

    let package = Package(
        name: "{{name}}",
        products: [
            .executable(name: "{{name}}", targets: ["{{target}}"]),
        ],
        dependencies: [
            //.package(url: "https://github.com/Hejki/CommandLineAPI", from: "0.1.0"),
        ],
        targets: [
            .target(
                name: "{{target}}",
                dependencies: [],
                path: "Sources"
            ),{% if use_tests %}
            .testTarget(
                name: "{{target}}Tests",
                dependencies: ["{{target}}"]
            ),{% endif %}
        ]
    )

    """

    static var stoolConfig = """
    product: '{{ name }}'

    # Define target install path for `stool install` command
    install_path: /usr/local/bin

    # Build configuration (debug|release)
    build_config: {{ build_config|default:"release" }}

    """

    static let main = """
    import Foundation{% for dep in dependencies %}
    import {{ dep.moduleName }}{% endfor %}

    print("Hi!")

    """

    static let swiftformat = """
    --disable blankLinesAroundMark,redundantSelf,blankLinesAtStartOfScope,andOperator
    --exclude Package.swift
    --exclude Tests/{{target}}Tests/XCTestManifests.swift
    --exclude Tests/LinuxMain.swift
    --stripunusedargs closure-only
    --ifdef no-indent
    --header "/*\\n *  {{name}}\\n *\\n *  Copyright (c) {year} {{author}}. Licensed under the MIT license, as follows:\\n *\\n *  Permission is hereby granted, free of charge, to any person obtaining a copy\\n *  of this software and associated documentation files (the "Software"), to deal\\n *  in the Software without restriction, including without limitation the rights\\n *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\\n *  copies of the Software, and to permit persons to whom the Software is\\n *  furnished to do so, subject to the following conditions:\\n *\\n *  The above copyright notice and this permission notice shall be included in all\\n *  copies or substantial portions of the Software.\\n *\\n *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\\n *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\\n *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\\n *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\\n *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\\n *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\\n *  SOFTWARE.\\n */"

    """

    static let exampleTest = """
    import XCTest
    @testable import {{target}}

    final class {{Target}}Tests: XCTestCase {
    }

    """

    static let license = """
    MIT License

    Copyright (c) {{ currentDate|format:"yyyy" }} {{author}}

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    """
}
