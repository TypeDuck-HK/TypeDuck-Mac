import Foundation
import SQLite3

@main
struct Preparing {
        static func main() {
                SyllablePreparer.prepare()
                DatabasePreparer.prepare()
        }
}
