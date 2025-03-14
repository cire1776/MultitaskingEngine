//
//  PreBuildPlugin.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/10/25.
//

import Foundation
import PackagePlugin

@main
struct PreBuildScriptPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let projectRoot = context.package.directoryURL.path

        print("🚀 [Pre-Build Plugin] Executing for target \(target.name)")
        print("📂 Setting PROJECT_ROOT: \(projectRoot)") // ✅ Debug output

        return [
            .prebuildCommand(
                displayName: "Running Pre-Build Script",
                executable: URL(fileURLWithPath: "/bin/sh"),
                arguments: [context.package.directoryURL.appendingPathComponent("Scripts/prebuild.sh").path],
                environment: [
                    "PROJECT_ROOT": projectRoot, // ✅ Set environment variable
                    "TARGET_NAME": target.name
                ],
                outputFilesDirectory: context.pluginWorkDirectoryURL.appendingPathComponent("PreBuildOutputs")
            )
        ]
    }
}
