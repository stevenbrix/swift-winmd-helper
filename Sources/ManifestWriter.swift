
import DotNetMetadata
import DotNetMetadataFormat
import Foundation
import WindowsMetadata

class ManifestWriter {
    static func write(typesFrom: Assembly, dllName: String, to outputFile: URL) throws {
        var activations = [String]()
        for type in assembly.definedTypes {
            if try type.hasAttribute(ActivatableAttribute.self) {
                activations.append("""
            <activatableClass
                name="\(type.name)"
                threadingModel="both"
                xmlns="urn:schemas-microsoft-com:winrt.v1" />
        """)
            }
        }

        try """
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity version="1.0.0.0" name="\(assembly.name)"/>
  <file name="\(dllName)">
    \(activations.joined(separator: "\n"))
  </file>
</assembly>
""".write(to: outputFile, atomically: true, encoding: .utf8)
    }
}