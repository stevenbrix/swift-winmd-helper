// The Swift Programming Language
// https://docs.swift.org/swift-book

import DotNetMetadata
import DotNetMetadataFormat
import Foundation

enum WinmdError: Error {
    case missingWinmdArgument
    case missingOutputArgument
}

guard let index = CommandLine.arguments.firstIndex(of: "--winmd") else {
    throw WinmdError.missingWinmdArgument
}

let winmdPath = CommandLine.arguments[index + 1]

let implFile = {
    guard let implDll = CommandLine.arguments.firstIndex(of: "--impl") else {
        return String(winmdPath.split(separator: "\\").last!.dropLast(5) + "dll")
    }

    return CommandLine.arguments[implDll + 1]
}()

guard let outputIndex = CommandLine.arguments.firstIndex(of: "--output") else {
    throw WinmdError.missingOutputArgument
}

let output = CommandLine.arguments[outputIndex + 1]

let systemDir = ProcessInfo.processInfo.environment["WindowsSdkDir"]!
let sdkVer = ProcessInfo.processInfo.environment["WindowsSDKVersion"]!
let metadataDir = URL(fileURLWithPath: systemDir).appendingPathComponent("References").appendingPathComponent(sdkVer)
let context = AssemblyLoadContext() {
    print("resolving \($0)")
    let filePath = metadataDir.appendingPathComponent($0.version!.description).appendingPathComponent("\($0.name).winmd")
    print("trying to load \(filePath)")

    if ($0.name == "mscorlib") {
        return try ModuleFile(url: URL(fileURLWithPath: #"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\mscorlib.dll"#))
    }
    if ($0.name == "Windows.Foundation.FoundationContract") {
        return try ModuleFile(url: metadataDir.appendingPathComponent("Windows.Foundation.winmd"))
    }
    return try ModuleFile(url: filePath)
}
let assembly = try context.load(path: winmdPath)
print("generating activations from \(winmdPath) for \(implFile)")
let outputFile = URL(fileURLWithPath: output).appendingPathComponent("\(assembly.name).manifest")

try ManifestWriter.write(typesFrom: assembly, dllName: implFile, to: outputFile)
//try HeaderWriter.write(typesFrom: assembly, to: URL(fileURLWithPath: output))