import Foundation
import Spinner

let spinner = Spinner(.dots, "foo bar baz", format: "{S} {T} {D}")
spinner.start()
sleep(5) // do work
spinner.stop()
