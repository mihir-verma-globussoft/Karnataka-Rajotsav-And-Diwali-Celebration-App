import Flutter
import UIKit
import XCTest
import simd

@testable import Runner

class RunnerTests: XCTestCase {

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

}

/// Same cases as ArItemSightTest on Android, so both phones agree.
///
/// The rule is "shown unless blocked", not "shown only once confirmed clear":
/// a hit test that finds nothing is the normal case on a blank wall, dim
/// corner or a spot ARKit/ARCore has not mapped yet, and must never be read
/// as "there is a wall here." Only a surface the phone actually tracked,
/// strictly nearer than the item, counts as blocking it.
final class ArItemSightTests: XCTestCase {
  private let far: Float = 3
  private let close: Float = 1

  func testAnItemIsShownFromTheStartWithNoReadingAtAll() {
    XCTAssertTrue(ArItemSight().isShown(now: 0))
  }

  func testAHitTestThatFindsNothingChangesNothing() {
    var sight = ArItemSight()
    sight.update(nearestSurface: nil, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(now: 0), "no data is not evidence of a wall")
  }

  func testSeeingTheSurfaceTheItemRestsOnKeepsItShown() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(now: 0))
  }

  func testSeeingASurfaceBeyondTheItemKeepsItShown() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far + 2, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(now: 0))
  }

  func testATrackedSurfaceInFrontHidesItEvenCloseUp() {
    var sight = ArItemSight()
    sight.update(nearestSurface: close - 0.5, itemDistance: close, now: 0)
    sight.update(nearestSurface: close - 0.5, itemDistance: close, now: 0.25)
    XCTAssertFalse(sight.isShown(now: 0.25))
  }

  func testOneOddReadingDoesNotHideIt() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far, itemDistance: far, now: 0)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.25)
    XCTAssertTrue(sight.isShown(now: 0.25))
  }

  func testASurfaceOnlyJustInFrontIsTheOneItStandsOn() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far - 0.2, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(now: 0))
  }

  func testOnceHiddenAClearReadingShowsItAgain() {
    var sight = ArItemSight()
    sight.update(nearestSurface: 1, itemDistance: far, now: 0)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.25)
    XCTAssertFalse(sight.isShown(now: 0.5))
    sight.update(nearestSurface: far, itemDistance: far, now: 0.5)
    XCTAssertTrue(sight.isShown(now: 0.5))
  }

  func testOnceHiddenASustainedRunWithNoReadingAlsoShowsItAgain() {
    var sight = ArItemSight()
    sight.update(nearestSurface: 1, itemDistance: far, now: 0)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.25)
    XCTAssertFalse(sight.isShown(now: 0.5))
    // No hit test lands for a while: that is not "still blocked".
    XCTAssertTrue(sight.isShown(now: 10), "no data must not hide something forever")
  }

  func testBeingBlockedIsRememberedForAShortHoldSoItNeverFlickers() {
    var sight = ArItemSight()
    sight.update(nearestSurface: 1, itemDistance: far, now: 0)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.25)
    XCTAssertFalse(sight.isShown(now: 0.26))
  }
}

/// A tap on something with no flat surface, like the side of a computer.
final class ArFeatureDepthTests: XCTestCase {
  private let origin = SIMD3<Float>(0, 0, 0)
  private let ahead = SIMD3<Float>(0, 0, -1)

  func testFindsTheThingUnderTheFinger() throws {
    let points = [SIMD3<Float>(0, 0, -2), SIMD3(0.01, 0, -2), SIMD3(0, 0.01, -2), SIMD3(0.01, 0.01, -2)]
    let depth = try XCTUnwrap(ArFeatureDepth.along(origin: origin, direction: ahead, points: points))
    XCTAssertEqual(depth, 2, accuracy: 0.01)
  }

  func testPrefersTheNearThingOverTheWallBehindIt() throws {
    let points =
      (0..<6).map { _ in SIMD3<Float>(0, 0, -1) } + (0..<6).map { _ in SIMD3<Float>(0, 0, -4) }
    let depth = try XCTUnwrap(ArFeatureDepth.along(origin: origin, direction: ahead, points: points))
    XCTAssertEqual(depth, 1, accuracy: 0.01)
  }

  func testIgnoresPointsAwayFromTheFinger() {
    let points = (0..<6).map { _ in SIMD3<Float>(1, 0, -2) }
    XCTAssertNil(ArFeatureDepth.along(origin: origin, direction: ahead, points: points))
  }

  func testIgnoresPointsBehindTheCamera() {
    let points = (0..<6).map { _ in SIMD3<Float>(0, 0, 2) }
    XCTAssertNil(ArFeatureDepth.along(origin: origin, direction: ahead, points: points))
  }

  func testOneStrayPointIsNotEnough() {
    XCTAssertNil(ArFeatureDepth.along(origin: origin, direction: ahead, points: [SIMD3(0, 0, -2)]))
  }
}
