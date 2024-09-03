import Foundation
import Spinner

let spinner = Spinner(.dots, "foo bar baz", format: "{S} {T} {D}")
spinner.start()
sleep(1) // do work
spinner.log("\(Date()) first")
sleep(1)
spinner.log("\(Date()) second")
sleep(3)
spinner.success()
