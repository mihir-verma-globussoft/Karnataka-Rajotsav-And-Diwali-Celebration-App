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
final class ArItemSightTests: XCTestCase {
  private let far: Float = 3
  private let close: Float = 1

  func testAnItemAcrossTheRoomStaysHiddenUntilAClearViewIsConfirmed() {
    var sight = ArItemSight()
    XCTAssertFalse(sight.isShown(itemDistance: far, now: 0))
    sight.update(nearestSurface: nil, itemDistance: far, now: 0)
    XCTAssertFalse(sight.isShown(itemDistance: far, now: 0), "a plain wall gives no surface")
  }

  func testSeeingTheSurfaceTheItemRestsOnShowsIt() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(itemDistance: far, now: 0))
  }

  func testSeeingASurfaceBeyondTheItemShowsIt() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far + 2, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(itemDistance: far, now: 0))
  }

  func testATableOrWallInFrontHidesItEvenCloseUp() {
    var sight = ArItemSight()
    sight.update(nearestSurface: close - 0.5, itemDistance: close, now: 0)
    sight.update(nearestSurface: close - 0.5, itemDistance: close, now: 0.25)
    XCTAssertFalse(sight.isShown(itemDistance: close, now: 0.25))
  }

  func testOneOddReadingDoesNotHideIt() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far, itemDistance: far, now: 0)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.25)
    XCTAssertTrue(sight.isShown(itemDistance: far, now: 0.25))
  }

  func testASurfaceOnlyJustInFrontIsTheOneItStandsOn() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far - 0.2, itemDistance: far, now: 0)
    XCTAssertTrue(sight.isShown(itemDistance: far, now: 0))
  }

  func testRightNextToAnItemItShowsWithoutBeingConfirmed() {
    XCTAssertTrue(ArItemSight().isShown(itemDistance: close, now: 0))
  }

  func testOnceSeenItStaysShownWhileThePhoneHasNoAnswer() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far, itemDistance: far, now: 0)
    sight.update(nearestSurface: nil, itemDistance: far, now: 5)
    XCTAssertTrue(sight.isShown(itemDistance: far, now: 5), "no blinking between checks")
  }

  func testAfterBeingHiddenItNeedsAClearViewAgain() {
    var sight = ArItemSight()
    sight.update(nearestSurface: far, itemDistance: far, now: 0)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.25)
    sight.update(nearestSurface: 1, itemDistance: far, now: 0.5)
    XCTAssertFalse(sight.isShown(itemDistance: far, now: 3))
    sight.update(nearestSurface: far, itemDistance: far, now: 3)
    XCTAssertTrue(sight.isShown(itemDistance: far, now: 3))
  }

  func testTheOrganisersItemsStartShown() {
    XCTAssertTrue(ArItemSight(clear: true).isShown(itemDistance: far, now: 0))
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
