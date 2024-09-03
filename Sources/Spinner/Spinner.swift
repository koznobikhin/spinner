import Foundation
import Dispatch
import Rainbow
import Signals

enum Terminal {
    static func CSI(_ code: String) -> String {
        "\u{001B}[\(code)"
    }

    static func eraseInLine(_ value: Int) -> String {
        CSI("\(value)K")
    }

    enum Cursor {
        static let hide = CSI("?25l")
        static let show = CSI("?25h")

        static func horizontalAbsolute(_ value: Int) -> String {
            let value = max(1, value)
            return CSI("\(value)G")
        }
    }
}

struct StdOutSpinnerStream: SpinnerStream {
    func write(string: String, terminator: String) {
        print(string, terminator: terminator)
        fflush(stdout)
    }

    func hideCursor() {
        print(Terminal.Cursor.hide, terminator: "")
        fflush(stdout)
    }

    func showCursor() {
        print(Terminal.Cursor.show, terminator: "")
        fflush(stdout)
    }
}

struct DefaultSpinnerSignal: SpinnerSignal {
    func trap() {
        SignalWatch.shared.on(signal: .int) { _ in
            print(Terminal.Cursor.hide, terminator: "")
            exit(0)
        }
    }
}

public final class Spinner {
    var animation: SpinnerAnimation {
        didSet {
            self.frameIndex = 0
        }
    }
    var message: String
    var status: Bool
    var color: Color
    var speed: Double
    var format: String
    let stream: SpinnerStream

    var frameIndex: Int
    var queue: DispatchQueue
    var timestamp: ContinuousClock.Instant?

    /**
    Initialize spinner
    - Parameter animation: spinner animation
    - Parameter message: message to render
    - Parameter color: spinner animation color
    - Parameter speed: speed of spinner animation
    - Parameter format: spinner format
    - Parameter stream: output steam for spinner
    - Parameter signal: signal trap implementation for spinner
    */
    public init(
        _ animation: SpinnerAnimation,
        _ message: String = "",
        color: Color = .default,
        speed: Double? = nil,
        format: String = "{S} {T}",
        stream: SpinnerStream? = nil,
        signal: SpinnerSignal? = nil
    ) {
        self.animation = animation
        self.message = message
        self.color = color
        self.speed = speed ?? animation.defaultSpeed
        self.format = format.uppercased()
        self.stream = stream ?? StdOutSpinnerStream()

        self.frameIndex = 0
        self.status = false
        self.queue = DispatchQueue(label: "io.Swift.Spinner")
        if let signal = signal {
            signal.trap()
        }
        else {
            DefaultSpinnerSignal().trap()
        }
    }

    /**
    Start the spinner
    */
    public func start() {
        self.stream.hideCursor()
        self.status = true
        self.timestamp = ContinuousClock.now
        self.queue.async { [weak self] in
            self?.renderCycle()
        }
    }

    /**
    Stop the spinner
    - Parameter frame: final frame to render before stopping
    - Parameter message: final message to render before stopping
    - Parameter color: final frame color
    - Parameter terminator: the string to print after all items have been printed
    */
    public func stop(frame: String? = nil, message: String? = nil, color: Color? = nil, terminator: String = "\n") {
        self.queue.sync {
            self.status = false
            if let message = message {
                self.message(message)
            }
            if let color = color {
                self.color(color)
            }
            var animation: SpinnerAnimation?
            if let frame = frame {
                animation = SpinnerAnimation(frame: frame)
            }
            if let animation = animation {
                self.message += Array(repeating: " ", count: self.padding(animation))
                self.animation = animation
            }
            self.render()
            self.stream.write(string: "", terminator: terminator)
            self.stream.showCursor()
        }
    }

    /**
    Update spinner animation
    - Parameter animation: spinner animation
    */
    public func animation(_ animation: SpinnerAnimation) {
        self.format += Array(repeating: " ", count: self.padding(animation))
        self.animation = animation
    }

    /**
    Update spinner message
    - Parameter message: message to render
    */
    public func message(_ message: String) {
        self.format += Array(repeating: " ", count: self.padding(message))
        self.message = message
    }

    /**
    Update spinner animation speed
    - Parameter speed: speed of spinner animation
    */
    public func speed(_ speed: Double) {
        self.speed = speed
    }

    /**
    Update spinner animation color
    - Parameter color: spinner animation color
    */
    public func color(_ color: Color) {
        self.color = color
    }

    /**
    Update spinner format
    - Parameter format: spinner format
    */
    public func format(_ format: String) {
        self.format = format
    }

    /**
    Stop and clear the spinner
    */
    public func clear() {
        self.stop(frame: "", message: "", terminator: "\r")
    }

    /**
    Stop and render a green tick for the final animation frame
    - Parameter message: spinner message to render
    */
    public func success(_ message: String? = nil) {
        self.stop(frame: "✔", message: message, color: .green)
    }

    /**
    Stop and render a red cross for the final animation frame
    - Parameter message: spinner message to render
    */
    public func error(_ message: String? = nil) {
        self.stop(frame: "✖", message: message, color: .red)
    }

    /**
    Stop and render a yellow warning symbol for the final animation frame
    - Parameter message: spinner message to render
    */
    public func warning(_ message: String? = nil) {
        self.stop(frame: "⚠", message: message, color: .yellow)
    }

    /**
    Stop and render a blue information sign  for the final animation frame
    - Parameter message: spinner message to render
    */
    public func info(_ message: String? = nil) {
        self.stop(frame: "ℹ", message: message, color: .blue)
    }
    
    /// Outputs message on top of the spinner
    /// - Parameter message: the message to output
    public func log(_ message: String) {
        self.queue.sync {
            clearLine()
            stream.write(string: message, terminator: "\n")
        }
    }

    private func entryLength(entry: Rainbow.Entry) -> Int {
      if let segment = entry.segments.first {
        return segment.text.count
      }
      return 0
    }

    private func padding(_ message: String) -> Int {
        let new = entryLength(entry: Rainbow.extractEntry(for: message))
        let old = entryLength(entry: Rainbow.extractEntry(for: self.message))
        let diff: Int = old - new
        if diff > 0 {
            return diff
        } else {
            return 0
        }
    }

    private func padding(_ animation: SpinnerAnimation) -> Int {
        let new = entryLength(entry: Rainbow.extractEntry(for: animation.frames[0]))
        let old = entryLength(entry: Rainbow.extractEntry(for: self.animation.frames[0]))
        let diff: Int = old - new
        if diff > 0 {
            return diff
        } else {
            return 0
        }
    }

    private func frame() -> String {
        let frame = self.animation.frames[self.frameIndex].applyingCodes(self.color)
        self.frameIndex = (self.frameIndex + 1) % self.animation.frames.count
        return frame
    }

    private func render() {
        var spinner = self.format.replacingOccurrences(of: "{S}", with: self.frame()).replacingOccurrences(of: "{T}", with: self.message)
        if let timestamp = self.timestamp {
            let duration = ContinuousClock.now - timestamp
            spinner = spinner.replacingOccurrences(of: "{D}", with: duration.formatted(.units(width: .narrow)))
        }
        clearLine()
        stream.write(string: spinner, terminator: "")
    }

    private func clearLine() {
        let clearLine = Terminal.Cursor.horizontalAbsolute(1) + Terminal.eraseInLine(2)
        stream.write(string: clearLine, terminator: "")
    }

    private func renderCycle() {
        guard self.status else { return }
        self.render()
        self.queue.asyncAfter(deadline: .now() + self.speed) { [weak self] in
            self?.renderCycle()
        }
    }
}
