import Flutter
import UIKit

final class ArHuntViewFactory: NSObject, FlutterPlatformViewFactory {
  static let viewType = "festival_app/ar_view"

  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    ArHuntView(
      frame: frame,
      viewId: viewId,
      messenger: messenger,
      args: args as? [String: Any] ?? [:]
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

#if targetEnvironment(simulator)

/// The simulator has no ARKit, so `ArChannel` reports AR as unsupported there
/// and this is never shown.
final class ArHuntView: NSObject, FlutterPlatformView {
  private let placeholder: UIView

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]) {
    placeholder = UIView(frame: frame)
  }

  func view() -> UIView { placeholder }
}

#else

import ARKit
import Combine
import RealityKit

private struct PartResource {
  let mesh: MeshResource
  let material: Material
  let flicker: Bool
  let pivot: SIMD3<Float>
}

private struct ModelResource {
  let height: Float
  let parts: [PartResource]
}

private final class SceneItem {
  let id: String
  let kind: String
  let local: SIMD3<Float>
  let root = Entity()
  var flames: [(entity: Entity, pivot: SIMD3<Float>)] = []
  let phase: Float
  var center = SIMD3<Float>.zero
  var distance: Float = 0

  init(id: String, kind: String, local: SIMD3<Float>) {
    self.id = id
    self.kind = kind
    self.local = local
    phase = Float(abs(id.hashValue) % 628) / 100
  }
}

private final class Spark {
  let entity: ModelEntity
  var position: SIMD3<Float>
  var velocity: SIMD3<Float>
  var age: Float = 0

  init(entity: ModelEntity, position: SIMD3<Float>, velocity: SIMD3<Float>) {
    self.entity = entity
    self.position = position
    self.velocity = velocity
  }
}

/// The camera and everything drawn in it. Dart decides what is shown and when
/// (see lib/features/ar/data/method_channel_ar_scene.dart); this only draws and
/// reports what ARKit sees. Everything here runs on the main thread.
final class ArHuntView: NSObject, FlutterPlatformView, ARSessionDelegate {
  private static let posterInterval: CFTimeInterval = 0.066
  private static let nearestInterval: CFTimeInterval = 0.5
  private static let appearDistance: Float = 1
  private static let wallOffset: Float = 0.12
  private static let floatingDistance: Float = 1.2
  private static let sparkCount = 18
  private static let sparkLife: Float = 0.8

  private let arView: ARView
  private let channel: FlutterMethodChannel
  private let placing: Bool
  private let reduceMotion: Bool
  private let visibleRadius: Float
  private let pickRadius: CGFloat
  private let posterArgs: [[String: Any]]
  private var models: [String: ModelResource] = [:]
  private var sparkMaterials: [UnlitMaterial] = []
  private let sparkMesh = MeshResource.generateSphere(radius: 1)
  private let sparkAnchor = AnchorEntity(world: .zero)

  private var items: [SceneItem] = []
  private var sparks: [Spark] = []
  private var originAnchor: ARAnchor?
  private var originEntity: AnchorEntity?
  private var updates: Cancellable?
  private var running = false
  private var trackingUsable = false
  private var lastTick = CACurrentMediaTime()
  private var lastPoster: CFTimeInterval = 0
  private var lastNearest: CFTimeInterval = 0

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]) {
    arView = ARView(frame: frame, cameraMode: .ar, automaticallyConfigureSession: false)
    channel = FlutterMethodChannel(
      name: "\(ArHuntViewFactory.viewType)_\(viewId)",
      binaryMessenger: messenger
    )
    placing = args["placing"] as? Bool ?? false
    reduceMotion = args["reduceMotion"] as? Bool ?? false
    visibleRadius = (args["visibleRadius"] as? NSNumber)?.floatValue ?? 6
    pickRadius = CGFloat((args["pickRadius"] as? NSNumber)?.floatValue ?? 72)
    posterArgs = args["posters"] as? [[String: Any]] ?? []
    super.init()

    arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    arView.renderOptions.formUnion([.disableMotionBlur, .disableDepthOfField])
    arView.session.delegate = self
    arView.scene.addAnchor(sparkAnchor)

    if let raw = args["models"] as? [String: [String: Any]] {
      models = raw.compactMapValues(ArHuntView.loadModel)
    }
    sparkMaterials = (args["sparkColors"] as? [NSNumber] ?? []).map {
      UnlitMaterial(color: ArHuntView.color($0).withAlphaComponent(1))
    }
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result) ?? result(nil)
    }
  }

  func view() -> UIView { arView }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      start()
    case "setOrigin":
      setOrigin(call.arguments as? [String: NSNumber])
    case "setItems":
      setItems(call.arguments as? [[String: Any]] ?? [])
    case "celebrate":
      if let id = call.arguments as? String { celebrate(id) }
    case "tap":
      if let point = call.arguments as? [String: NSNumber] {
        tap(CGPoint(x: point["x"]?.doubleValue ?? 0, y: point["y"]?.doubleValue ?? 0))
      }
    case "dispose":
      stop()
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    result(nil)
  }

  private func start() {
    guard !running else { return }
    running = true
    let configuration = ARWorldTrackingConfiguration()
    configuration.detectionImages = referenceImages()
    configuration.maximumNumberOfTrackedImages = 1
    configuration.environmentTexturing = .automatic
    configuration.planeDetection = placing ? [.horizontal, .vertical] : []
    arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    updates = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
      self?.tick()
    }
  }

  private func stop() {
    guard running else { return }
    running = false
    updates?.cancel()
    updates = nil
    arView.session.pause()
    channel.setMethodCallHandler(nil)
  }

  deinit {
    updates?.cancel()
    arView.session.pause()
  }

  private func referenceImages() -> Set<ARReferenceImage> {
    var images = Set<ARReferenceImage>()
    for poster in posterArgs {
      guard
        let id = poster["id"] as? String,
        let asset = poster["asset"] as? String,
        let width = (poster["width"] as? NSNumber)?.doubleValue,
        let path = Bundle.main.path(
          forResource: FlutterDartProject.lookupKey(forAsset: asset),
          ofType: nil
        ),
        let image = UIImage(contentsOfFile: path)?.cgImage
      else { continue }
      let reference = ARReferenceImage(image, orientation: .up, physicalWidth: CGFloat(width))
      reference.name = id
      images.insert(reference)
    }
    return images
  }

  // MARK: - What Dart asks for

  private func setOrigin(_ args: [String: NSNumber]?) {
    if let anchor = originAnchor { arView.session.remove(anchor: anchor) }
    originEntity?.removeFromParent()
    originAnchor = nil
    originEntity = nil
    guard let args else { return }
    let yaw = args["yaw"]?.floatValue ?? 0
    var transform = simd_float4x4(simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0)))
    transform.columns.3 = SIMD4<Float>(
      args["x"]?.floatValue ?? 0,
      args["y"]?.floatValue ?? 0,
      args["z"]?.floatValue ?? 0,
      1
    )
    // Tied to an ARKit anchor, so it follows ARKit's own drift corrections.
    let anchor = ARAnchor(name: "hunt-origin", transform: transform)
    arView.session.add(anchor: anchor)
    let entity = AnchorEntity(anchor: anchor)
    arView.scene.addAnchor(entity)
    originAnchor = anchor
    originEntity = entity
    for item in items { entity.addChild(item.root) }
  }

  private func setItems(_ args: [[String: Any]]) {
    for item in items { item.root.removeFromParent() }
    items = args.compactMap { raw in
      guard
        let id = raw["id"] as? String,
        let kind = raw["kind"] as? String,
        let x = (raw["x"] as? NSNumber)?.floatValue,
        let y = (raw["y"] as? NSNumber)?.floatValue,
        let z = (raw["z"] as? NSNumber)?.floatValue,
        let model = models[kind]
      else { return nil }
      let item = SceneItem(id: id, kind: kind, local: SIMD3(x, y, z))
      for part in model.parts {
        let entity = ModelEntity(mesh: part.mesh, materials: [part.material])
        item.root.addChild(entity)
        if part.flicker { item.flames.append((entity, part.pivot)) }
      }
      item.root.isEnabled = false
      originEntity?.addChild(item.root)
      return item
    }
  }

  private func celebrate(_ id: String) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    let item = items.remove(at: index)
    item.root.removeFromParent()
    guard !reduceMotion, !sparkMaterials.isEmpty else { return }
    for i in 0..<ArHuntView.sparkCount {
      let angle = Float(i) * 2.4
      let rise = 0.5 + Float(i % 5) * 0.2
      let entity = ModelEntity(
        mesh: sparkMesh,
        materials: [sparkMaterials[i % sparkMaterials.count]]
      )
      sparkAnchor.addChild(entity)
      sparks.append(
        Spark(
          entity: entity,
          position: item.center,
          velocity: SIMD3(cos(angle) * 0.7, rise, sin(angle) * 0.7)
        )
      )
    }
  }

  private func tap(_ point: CGPoint) {
    guard trackingUsable, let origin = originEntity, origin.isAnchored else { return }
    if let item = pick(point) {
      send("onItemTap", ["id": item.id, "distance": Double(item.distance)])
    } else if placing {
      reportSurface(at: point, origin: origin)
    }
  }

  /// The drawn item nearest the finger, generously, as items are small.
  private func pick(_ point: CGPoint) -> SceneItem? {
    let inverseCamera = arView.cameraTransform.matrix.inverse
    var best: SceneItem?
    var bestDistance = pickRadius
    for item in items where item.distance <= visibleRadius {
      let inCamera = inverseCamera * SIMD4(item.center, 1)
      guard inCamera.z < 0, let projected = arView.project(item.center) else { continue }
      let distance = hypot(projected.x - point.x, projected.y - point.y)
      if distance < bestDistance {
        best = item
        bestDistance = distance
      }
    }
    return best
  }

  private func reportSurface(at point: CGPoint, origin: AnchorEntity) {
    var world: SIMD3<Float>
    let onSurface: Bool
    if let hit = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
      let matrix = hit.worldTransform
      world = SIMD3(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
      let normal = SIMD3(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z)
      // On a wall, stand the item off it instead of half inside it.
      if abs(normal.y) < 0.7 { world += normal * ArHuntView.wallOffset }
      onSurface = true
    } else if let ray = arView.ray(through: point) {
      world = ray.origin + simd_normalize(ray.direction) * ArHuntView.floatingDistance
      onSurface = false
    } else {
      return
    }
    let local = origin.convert(position: world, from: nil)
    send(
      "onSurfaceTap",
      [
        "x": Double(local.x),
        "y": Double(local.y),
        "z": Double(local.z),
        "onSurface": onSurface,
      ]
    )
  }

  // MARK: - Every frame

  private func tick() {
    let now = CACurrentMediaTime()
    let dt = Float(now - lastTick)
    lastTick = now
    // Wrapped, because a Float cannot hold a long uptime precisely.
    let time = Float(now.truncatingRemainder(dividingBy: 1000))
    let cameraMatrix = arView.cameraTransform.matrix
    let camera = SIMD3(cameraMatrix.columns.3.x, cameraMatrix.columns.3.y, cameraMatrix.columns.3.z)
    if let origin = originEntity, origin.isAnchored {
      let originMatrix = origin.transformMatrix(relativeTo: nil)
      for item in items {
        place(item, originMatrix: originMatrix, camera: camera, time: time)
      }
      reportNearest(now: now, cameraMatrix: cameraMatrix)
    }
    moveSparks(dt: dt)
  }

  private func place(
    _ item: SceneItem,
    originMatrix: simd_float4x4,
    camera: SIMD3<Float>,
    time: Float
  ) {
    let world4 = originMatrix * SIMD4(item.local, 1)
    let world = SIMD3(world4.x, world4.y, world4.z)
    let height = models[item.kind]?.height ?? 0
    item.center = world + SIMD3(0, height / 2, 0)
    item.distance = simd_distance(camera, world)
    // Items are hidden until tracking returns, so they never jump around.
    let visible = trackingUsable && item.distance <= visibleRadius
    item.root.isEnabled = visible
    guard visible else { return }
    let bob = reduceMotion ? 0 : 0.015 * sin(1.6 * time + item.phase)
    let sway = reduceMotion ? 0 : 0.25 * sin(0.8 * time + item.phase)
    let t = min(max((visibleRadius - item.distance) / ArHuntView.appearDistance, 0), 1)
    let appear = max(t * t * (3 - 2 * t), 0.001)
    let yaw = atan2(camera.x - world.x, camera.z - world.z) + sway
    item.root.setPosition(world + SIMD3(0, bob, 0), relativeTo: nil)
    item.root.setOrientation(simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0)), relativeTo: nil)
    item.root.setScale(SIMD3(repeating: appear), relativeTo: nil)
    guard !reduceMotion else { return }
    let flicker = 1 + 0.08 * sin(11 * time + item.phase) + 0.04 * sin(17 * time)
    let side = 1 + (1 - flicker) / 2
    let scale = SIMD3(side, flicker, side)
    for flame in item.flames {
      flame.entity.transform = Transform(
        scale: scale,
        rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
        translation: flame.pivot - scale * flame.pivot
      )
    }
  }

  private func moveSparks(dt: Float) {
    sparks.removeAll { spark in
      spark.age += dt
      if spark.age >= ArHuntView.sparkLife {
        spark.entity.removeFromParent()
        return true
      }
      spark.velocity.y -= 1.6 * dt
      spark.position += spark.velocity * dt
      spark.entity.position = spark.position
      spark.entity.scale = SIMD3(repeating: 0.02 * (1 - spark.age / ArHuntView.sparkLife))
      return false
    }
  }

  private func reportNearest(now: CFTimeInterval, cameraMatrix: simd_float4x4) {
    guard
      !placing,
      now - lastNearest >= ArHuntView.nearestInterval,
      let nearest = items.min(by: { $0.distance < $1.distance })
    else { return }
    lastNearest = now
    let local = cameraMatrix.inverse * SIMD4(nearest.center, 1)
    var onScreen = false
    if local.z < 0, nearest.distance <= visibleRadius, let point = arView.project(nearest.center) {
      onScreen = arView.bounds.contains(point)
    }
    send(
      "onNearest",
      [
        "id": nearest.id,
        "distance": Double(nearest.distance),
        "bearing": Double(atan2(local.x, -local.z)),
        "onScreen": onScreen,
      ]
    )
  }

  // MARK: - What ARKit reports

  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) { reportPosters(anchors) }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) { reportPosters(anchors) }

  private func reportPosters(_ anchors: [ARAnchor]) {
    let now = CACurrentMediaTime()
    guard now - lastPoster >= ArHuntView.posterInterval else { return }
    for case let image as ARImageAnchor in anchors where image.isTracked {
      guard let id = image.referenceImage.name else { continue }
      lastPoster = now
      let pose = image.transform
      let camera = arView.cameraTransform.matrix.columns.3
      send(
        "onPoster",
        [
          "id": id,
          "pose": [pose.columns.0, pose.columns.1, pose.columns.2, pose.columns.3].flatMap {
            [Double($0.x), Double($0.y), Double($0.z), Double($0.w)]
          },
          "camera": [Double(camera.x), Double(camera.y), Double(camera.z)],
        ]
      )
      return
    }
  }

  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    let state: String
    switch camera.trackingState {
    case .normal:
      state = "normal"
    case .notAvailable:
      state = "unavailable"
    case .limited(.initializing):
      state = "initializing"
    case .limited(.excessiveMotion):
      state = "tooFast"
    case .limited(.insufficientFeatures):
      state = "lowDetail"
    case .limited:
      state = "unavailable"
    @unknown default:
      state = "unavailable"
    }
    trackingUsable = state == "normal" || state == "tooFast" || state == "lowDetail"
    send("onTracking", ["state": state])
  }

  func sessionInterruptionEnded(_ session: ARSession) {
    send("onInterrupted", nil)
  }

  func session(_ session: ARSession, didFailWithError error: Error) {
    NSLog("AR session failed: %@", error.localizedDescription)
    send("onError", ["code": "session_failed"])
  }

  private func send(_ method: String, _ arguments: Any?) {
    channel.invokeMethod(method, arguments: arguments)
  }

  // MARK: - Models, built by `ArModel.toWire()` in Dart

  private static func loadModel(_ raw: [String: Any]) -> ModelResource? {
    guard
      let height = (raw["height"] as? NSNumber)?.floatValue,
      let parts = raw["parts"] as? [[String: Any]]
    else { return nil }
    return ModelResource(height: height, parts: parts.compactMap(loadPart))
  }

  private static func loadPart(_ raw: [String: Any]) -> PartResource? {
    guard
      let positions = raw["positions"] as? FlutterStandardTypedData,
      let normals = raw["normals"] as? FlutterStandardTypedData,
      let indices = raw["indices"] as? FlutterStandardTypedData,
      let argb = raw["argb"] as? NSNumber
    else { return nil }
    var descriptor = MeshDescriptor(name: "part")
    descriptor.positions = MeshBuffers.Positions(vectors(positions))
    descriptor.normals = MeshBuffers.Normals(vectors(normals))
    descriptor.primitives = .triangles(
      indices.data.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }
    )
    guard let mesh = try? MeshResource.generate(from: [descriptor]) else { return nil }
    let pivot = (raw["pivot"] as? [NSNumber] ?? []).map(\.floatValue)
    return PartResource(
      mesh: mesh,
      material: material(argb: argb, unlit: raw["unlit"] as? Bool ?? false),
      flicker: raw["flicker"] as? Bool ?? false,
      pivot: pivot.count == 3 ? SIMD3(pivot[0], pivot[1], pivot[2]) : .zero
    )
  }

  private static func vectors(_ data: FlutterStandardTypedData) -> [SIMD3<Float>] {
    let floats = data.data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    return stride(from: 0, to: floats.count, by: 3).map {
      SIMD3(floats[$0], floats[$0 + 1], floats[$0 + 2])
    }
  }

  private static func material(argb: NSNumber, unlit: Bool) -> Material {
    let color = color(argb)
    guard unlit else {
      return SimpleMaterial(color: color, roughness: 0.55, isMetallic: false)
    }
    var alpha: CGFloat = 1
    color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
    var material = UnlitMaterial(color: color.withAlphaComponent(1))
    if alpha < 1 {
      material.blending = .transparent(opacity: .init(floatLiteral: Float(alpha)))
    }
    return material
  }

  private static func color(_ argb: NSNumber) -> UIColor {
    let value = argb.uint32Value
    return UIColor(
      red: CGFloat((value >> 16) & 0xFF) / 255,
      green: CGFloat((value >> 8) & 0xFF) / 255,
      blue: CGFloat(value & 0xFF) / 255,
      alpha: CGFloat((value >> 24) & 0xFF) / 255
    )
  }
}

#endif
