import DotNetMetadata
import DotNetMetadataFormat
import Foundation
import WindowsMetadata

extension ClassDefinition {
    var defaultInterface: BoundInterface? {
        get throws {
            try DefaultAttribute.getDefaultInterface(self)
        }
    }
}

class HeaderWriter {

    static func writeType(type: ClassDefinition, to outputDir: URL) throws {
        guard type.name != "<Module>" else { return }

        var methods = [String]()
        for method in type.methods {
            var params = try method.params.map { try "\($0.type) \($0.name)" }.joined(separator: ", ")
            if try method.hasReturnValue {
                params += ", \(try method.returnType)"
            }
            methods.append("IFACEMETHOD(\(params));")
        }
        try """
#pragma once
#include <wrl.h>
#include <arc/ArcCoreWin.h>

namespace ABI::ArcCoreWinRT {

class \(type.name) : public Microsoft::WRL::RuntimeClass<
                               Microsoft::WRL::RuntimeClassFlags<
                                   Microsoft::WRL::RuntimeClassType::WinRt>,
                               \(type.defaultInterface!.definition.name)> {
public:
    InspectableClass(RuntimeClass_\(type.namespace!)_\(type.name)), BaseTrust)
    \(methods.joined(separator: "\n"))
}

}
""".write(to: outputDir.appendingPathComponent("\(type.name).h"), atomically: true, encoding: .utf8)
    }

  static func write(typesFrom: Assembly, to outputDir: URL) throws {
    for type in typesFrom.definedTypes {
        if let classType = type as? ClassDefinition {
            try writeType(type: classType, to: outputDir)
        }
    }
  }
}