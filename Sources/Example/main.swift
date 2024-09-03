import Foundation
import Spinner
import Rainbow

let spinner = Spinner(.dots, "foo bar baz", format: "{S} {T} {D}")
spinner.start()
sleep(1) // do work
spinner.log("\("ℹ".blue) first log message")
sleep(1)
spinner.log("\("ℹ".blue) second log message")
sleep(3)
spinner.success()
