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

let VERSION = "0.1.0"
let DEFAULT_SWIFT_VERSION = "5.0"
let MAIN_CONFIG_PATH = Path.home.appending(".stool/config.yml")
let STR_STOOL = "stool".styled(.fgYellow)
let STR_FORMAT_PATH = CLI.StringStyle.bright(.fgYellow)

let config: MainConfig
do {
    config = try MainConfig.load(MAIN_CONFIG_PATH)
} catch let SToolError.configNotExist(path) {
    CLI.println(error: "The config file \(path, style: STR_FORMAT_PATH) does not exist.")
    config = SToolMainConfigInit(path).run()
} catch let SToolError.configDecodeError(path, error) {
    CLI.println(error: """
    💩 Cannot read config file \(path, style: STR_FORMAT_PATH)
    Error: \(error.localizedDescription, style: .bright(.fgRed))
    """)
    exit(2)
}

let app = Group { mainGroup in

    mainGroup.command(
        "init",
        Option("template", default: "default", flag: "t", description: "Define tool template."),
        Flag("quiet", default: false, flag: "q", description: "Quiet mode. Disable coversation."),
        VariadicOption("variable", default: [], flag: "v", description: "Define variable which can be used in template."),
        Argument<String?>("name_or_path", description: "Name or path to a new tool."),
        description: "Creates a new swift tool project.",
        cmdInitTool
    )

    mainGroup.command(
        "install",
        description: "Build and install the current tool.",
        cmdInstallTool
    )

    mainGroup.group("templates", "Show list of templates and manage them") { templateGroup in

        templateGroup.command(
            "add",
            Argument("name", description: "A name for copy the default template."),
            description: "Copy the default template with a new name.",
            TemplateManager().install
        )

        templateGroup.command(
            "remove",
            Flag("force", default: false, flag: "f", description: "Force delete, never prompt."),
            Argument("template", description: "The name of the template to remove."),
            description: "Remove the specified template.",
            TemplateManager().remove
        )

        templateGroup.command(
            "default",
            description: "Copy the default template to the templates directory.",
            TemplateManager().installDefault
        )

        templateGroup.command(
            "list",
            description: "Show a list of all available templates.",
            TemplateManager().listTemplates
        )
    }
}

app.run(VERSION)
