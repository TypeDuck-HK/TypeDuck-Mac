import Foundation
import SQLite3

@main
struct Preparing {
        static func main() {
                SyllableDBHandler.prepare()
                IMEDBHandler.prepare()
        }
}
