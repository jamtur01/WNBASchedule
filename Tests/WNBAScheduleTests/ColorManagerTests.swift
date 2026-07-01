import XCTest
import SwiftUI
import AppKit
@testable import WNBASchedule

final class ColorManagerTests: XCTestCase {

    // MARK: - Helpers

    /// Concrete sRGB channel values for assertion.
    private struct Channels {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    /// Resolve a SwiftUI `Color` to concrete sRGB channel values for assertion.
    private func components(_ color: Color) -> Channels? {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        return Channels(
            red: srgb.redComponent,
            green: srgb.greenComponent,
            blue: srgb.blueComponent,
            alpha: srgb.alphaComponent
        )
    }

    /// Assert a color resolves to the given sRGB channel values.
    private func assertColor(
        _ color: Color,
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat = 1.0,
        accuracy: CGFloat = 0.01,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let resolved = components(color) else {
            XCTFail("Could not convert color to sRGB", file: file, line: line)
            return
        }
        XCTAssertEqual(resolved.red, red, accuracy: accuracy, "red channel", file: file, line: line)
        XCTAssertEqual(resolved.green, green, accuracy: accuracy, "green channel", file: file, line: line)
        XCTAssertEqual(resolved.blue, blue, accuracy: accuracy, "blue channel", file: file, line: line)
        XCTAssertEqual(resolved.alpha, alpha, accuracy: accuracy, "alpha channel", file: file, line: line)
    }

    /// Assert two colors resolve to the same sRGB channel values (both converted identically).
    private func assertSameColor(
        _ actual: Color,
        _ expected: Color,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actualChannels = components(actual),
              let expectedChannels = components(expected) else {
            XCTFail("Could not convert colors to sRGB", file: file, line: line)
            return
        }
        XCTAssertEqual(actualChannels.red, expectedChannels.red, accuracy: 0.01, "red channel", file: file, line: line)
        XCTAssertEqual(actualChannels.green, expectedChannels.green, accuracy: 0.01, "green channel", file: file, line: line)
        XCTAssertEqual(actualChannels.blue, expectedChannels.blue, accuracy: 0.01, "blue channel", file: file, line: line)
        XCTAssertEqual(actualChannels.alpha, expectedChannels.alpha, accuracy: 0.01, "alpha channel", file: file, line: line)
    }

    // MARK: - Color(hex:) — 6-digit parsing

    func testHexSixDigitRed() throws {
        let color = try XCTUnwrap(Color(hex: "#FF0000"))
        assertColor(color, red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

    func testHexSixDigitGreenWithoutHash() throws {
        let color = try XCTUnwrap(Color(hex: "00FF00"))
        assertColor(color, red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
    }

    func testHexSixDigitArbitrary() throws {
        // #1F2937 -> 31/255, 41/255, 55/255
        let color = try XCTUnwrap(Color(hex: "#1F2937"))
        assertColor(color, red: 0.122, green: 0.161, blue: 0.216, alpha: 1.0)
    }

    // MARK: - Color(hex:) — 3-digit shorthand

    func testHexThreeDigitRed() throws {
        // #F00 expands each nibble over 15.0
        let color = try XCTUnwrap(Color(hex: "#F00"))
        assertColor(color, red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

    func testHexThreeDigitWhite() throws {
        let color = try XCTUnwrap(Color(hex: "#FFF"))
        assertColor(color, red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }

    // MARK: - Color(hex:) — 8-digit with alpha

    func testHexEightDigitAlpha() throws {
        // #FF000080 -> red, alpha 128/255 ≈ 0.502
        let color = try XCTUnwrap(Color(hex: "#FF000080"))
        assertColor(color, red: 1.0, green: 0.0, blue: 0.0, alpha: 0.502)
    }

    // MARK: - Color(hex:) — whitespace tolerance

    func testHexWhitespaceTolerated() throws {
        let color = try XCTUnwrap(Color(hex: "  #FF0000  "))
        assertColor(color, red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

    // MARK: - Color(hex:) — malformed returns nil

    func testHexNonHexCharactersReturnNil() {
        XCTAssertNil(Color(hex: "#GGGGGG"))
    }

    func testHexWrongLengthsReturnNil() {
        XCTAssertNil(Color(hex: "#FF"), "2 hex digits should be nil")
        XCTAssertNil(Color(hex: "#FFFF"), "4 hex digits should be nil")
        XCTAssertNil(Color(hex: "#FFFFF"), "5 hex digits should be nil")
        XCTAssertNil(Color(hex: "#FFFFFFF"), "7 hex digits should be nil")
    }

    func testHexEmptyStringReturnsNil() {
        XCTAssertNil(Color(hex: ""))
    }

    // MARK: - contrastingText(on:) — legibility contract

    func testContrastingTextOnPureWhiteIsBlack() throws {
        let fill = try XCTUnwrap(Color(hex: "#FFFFFF"))
        assertSameColor(ColorManager.contrastingText(on: fill), .black)
    }

    func testContrastingTextOnNearWhiteIsBlack() throws {
        let fill = try XCTUnwrap(Color(hex: "#F9FAFB"))
        assertSameColor(ColorManager.contrastingText(on: fill), .black)
    }

    func testContrastingTextOnDarkSlateIsWhite() throws {
        let fill = try XCTUnwrap(Color(hex: "#1F2937"))
        assertSameColor(ColorManager.contrastingText(on: fill), .white)
    }

    func testContrastingTextOnBlackIsWhite() throws {
        let fill = try XCTUnwrap(Color(hex: "#000000"))
        assertSameColor(ColorManager.contrastingText(on: fill), .white)
    }

    func testContrastingTextOnBrightLimeIsBlack() throws {
        // WNBA DAL dark: high relative luminance despite vivid hue
        let fill = try XCTUnwrap(Color(hex: "#C4D630"))
        assertSameColor(ColorManager.contrastingText(on: fill), .black)
    }

    func testContrastingTextOnDeepOrangeIsWhite() throws {
        let fill = try XCTUnwrap(Color(hex: "#C2410C"))
        assertSameColor(ColorManager.contrastingText(on: fill), .white)
    }
}
