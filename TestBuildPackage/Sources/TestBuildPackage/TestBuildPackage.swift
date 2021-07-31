import Proton

// The purpose of this package is only to validate Proton as a dependency
// and ensure that imports like UIKit are not missed when adding a new file
// For ref: https://github.com/rajdeep/proton/pull/123
struct TestBuildPackage {
    var text = "Hello, World!"
}
