package com.globus.rajotsav_and_diwali_celebration_app.ar

import android.content.Context
import android.graphics.BitmapFactory
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.ar.core.Anchor
import com.google.ar.core.AugmentedImage
import com.google.ar.core.AugmentedImageDatabase
import com.google.ar.core.Camera
import com.google.ar.core.Config
import com.google.ar.core.DepthPoint
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.Pose
import com.google.ar.core.Session
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.SessionPausedException
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.ConcurrentLinkedQueue
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

class ArHuntViewFactory(
    private val activity: FlutterActivity,
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    @Suppress("UNCHECKED_CAST")
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView =
        ArHuntView(activity, viewId, messenger, args as Map<String, Any?>)

    companion object {
        const val VIEW_TYPE = "festival_app/ar_view"
    }
}

private class SceneItem(
    val id: String,
    val kind: String,
    val local: FloatArray,
    val scale: Float,
    val yaw: Float,
    val sight: ArItemSight,
) {
    val phase = (id.hashCode() and 0xFFFF) / 0xFFFF.toFloat() * 6.28f
    var center = FloatArray(3)
    var distance = 0f
    var pin: Anchor? = null

    fun unpin() {
        pin?.detach()
        pin = null
    }
}

private class Spark(
    val position: FloatArray,
    val velocity: FloatArray,
    val rgba: FloatArray,
    var age: Float = 0f,
)

/**
 * The camera and everything drawn in it. Dart decides what is shown and when
 * (see lib/features/ar/data/method_channel_ar_scene.dart); this only draws and
 * reports what ARCore sees. ARCore calls stay on the GL thread, except pausing.
 */
internal class ArHuntView(
    private val activity: FlutterActivity,
    viewId: Int,
    messenger: BinaryMessenger,
    args: Map<String, Any?>,
) : PlatformView, GLSurfaceView.Renderer, DefaultLifecycleObserver {
    private val channel = MethodChannel(messenger, "festival_app/ar_view_$viewId")
    private val main = Handler(Looper.getMainLooper())
    private val glView = GLSurfaceView(activity)
    private val density = activity.resources.displayMetrics.density

    private val placing = args["placing"] as Boolean
    private val reduceMotion = args["reduceMotion"] as Boolean
    private val visibleRadius = (args["visibleRadius"] as Number).toFloat()
    private val pickRadius = (args["pickRadius"] as Number).toFloat() * density
    private val modelArgs = args["models"] as Map<*, *>
    private val posterArgs = args["posters"] as List<*>
    private val sparkColors = (args["sparkColors"] as List<*>).map { rgbaOf(it as Number) }

    @Volatile private var session: Session? = null
    @Volatile private var active = false
    private var started = false
    private var creating = false
    private var disposed = false

    // Everything below belongs to the GL thread.
    private var meshes: Map<String, ArModelMesh> = emptyMap()
    private var sparkMesh: ArMesh? = null
    private val renderer = ArGlPrograms()
    private var viewportWidth = 1
    private var viewportHeight = 1
    private var geometryPending = false
    private var origin: Anchor? = null
    private var pendingOrigin: Pose? = null
    private var items = listOf<SceneItem>()
    private val sparks = mutableListOf<Spark>()
    private val taps = ConcurrentLinkedQueue<FloatArray>()
    private var lastFrameNanos = 0L
    private var lastNearestNanos = 0L
    private var lastPosterNanos = 0L
    private var lastSightCheckNanos = 0L
    private var lastTracking: String? = null
    private val viewMatrix = FloatArray(16)
    private val projectionMatrix = FloatArray(16)
    private val viewProjection = FloatArray(16)
    private val itemMatrix = FloatArray(16)
    private val partMatrix = FloatArray(16)
    private val mvp = FloatArray(16)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    started = true
                    if (activity.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) resumeSession()
                }
                "setOrigin" -> setOrigin(call.arguments as Map<*, *>?)
                "setItems" -> setItems(call.arguments as List<*>)
                "celebrate" -> celebrate(call.arguments as String)
                "tap" -> {
                    val point = call.arguments as Map<*, *>
                    taps.add(
                        floatArrayOf(
                            (point["x"] as Number).toFloat() * density,
                            (point["y"] as Number).toFloat() * density,
                        ),
                    )
                }
                "dispose" -> dispose()
                else -> {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
            }
            result.success(null)
        }
        glView.apply {
            preserveEGLContextOnPause = true
            setEGLContextClientVersion(2)
            setEGLConfigChooser(8, 8, 8, 8, 16, 0)
            setRenderer(this@ArHuntView)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }
        activity.lifecycle.addObserver(this)
    }

    override fun getView(): View = glView

    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        activity.lifecycle.removeObserver(this)
        active = false
        glView.onPause()
        session?.let {
            it.pause()
            it.close()
        }
        session = null
    }

    override fun onResume(owner: LifecycleOwner) {
        if (started) {
            resumeSession()
            send("onInterrupted", null)
        }
    }

    override fun onPause(owner: LifecycleOwner) {
        active = false
        glView.onPause()
        session?.pause()
    }

    private fun resumeSession() {
        if (disposed) return
        val current = session
        if (current == null) {
            createSession()
            return
        }
        try {
            current.resume()
            glView.onResume()
            active = true
            geometryPending = true
        } catch (error: Exception) {
            // Includes a camera permission revoked in settings mid-session.
            Log.e(TAG, "AR session could not resume", error)
            send("onError", mapOf("code" to "camera_unavailable"))
        }
    }

    /** Decoding the posters takes a moment, so it stays off the main thread. */
    private fun createSession() {
        if (creating) return
        creating = true
        Thread {
            try {
                val created = Session(activity)
                val database = AugmentedImageDatabase(created)
                val loader = FlutterInjector.instance().flutterLoader()
                for (raw in posterArgs) {
                    val poster = raw as Map<*, *>
                    val key = loader.getLookupKeyForAsset(poster["asset"] as String)
                    val bitmap = activity.assets.open(key).use(BitmapFactory::decodeStream)
                    // One poster ARCore rejects must not cost the other zones.
                    try {
                        database.addImage(poster["id"] as String, bitmap, (poster["width"] as Number).toFloat())
                    } catch (error: Exception) {
                        Log.e(TAG, "Poster ${poster["id"]} was rejected", error)
                    }
                }
                check(database.numImages > 0) { "ARCore rejected every poster" }
                created.configure(
                    Config(created).apply {
                        augmentedImageDatabase = database
                        focusMode = Config.FocusMode.AUTO
                        updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                        lightEstimationMode = Config.LightEstimationMode.AMBIENT_INTENSITY
                        planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                        // Lets hit tests find plain walls, on phones that can.
                        if (created.isDepthModeSupported(Config.DepthMode.AUTOMATIC)) {
                            depthMode = Config.DepthMode.AUTOMATIC
                        }
                    },
                )
                main.post {
                    creating = false
                    if (disposed) {
                        created.close()
                    } else {
                        session = created
                        if (activity.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) resumeSession()
                    }
                }
            } catch (error: Exception) {
                Log.e(TAG, "AR session could not start", error)
                main.post {
                    creating = false
                    send("onError", mapOf("code" to "session_failed"))
                }
            }
        }.start()
    }

    private fun setOrigin(args: Map<*, *>?) {
        val pose =
            args?.let {
                val half = (it["yaw"] as Number).toFloat() / 2
                Pose(
                    floatArrayOf(
                        (it["x"] as Number).toFloat(),
                        (it["y"] as Number).toFloat(),
                        (it["z"] as Number).toFloat(),
                    ),
                    floatArrayOf(0f, sin(half), 0f, cos(half)),
                )
            }
        glView.queueEvent {
            origin?.detach()
            origin = null
            pendingOrigin = pose
            items.forEach(SceneItem::unpin)
        }
    }

    private fun setItems(args: List<*>) {
        val next =
            args.map { raw ->
                val item = raw as Map<*, *>
                SceneItem(
                    item["id"] as String,
                    item["kind"] as String,
                    floatArrayOf(
                        (item["x"] as Number).toFloat(),
                        (item["y"] as Number).toFloat(),
                        (item["z"] as Number).toFloat(),
                    ),
                    (item["scale"] as Number).toFloat(),
                    (item["yaw"] as Number).toFloat(),
                    // The organiser sees what was just placed at once, then what players see.
                    ArItemSight(clear = placing),
                )
            }
        glView.queueEvent {
            items.forEach(SceneItem::unpin)
            items = next
        }
    }

    private fun celebrate(id: String) {
        glView.queueEvent {
            val item = items.firstOrNull { it.id == id } ?: return@queueEvent
            item.unpin()
            items = items.filter { it.id != id }
            if (reduceMotion || sparkColors.isEmpty()) return@queueEvent
            repeat(SPARK_COUNT) { index ->
                val angle = index * 2.4f
                val rise = 0.5f + (index % 5) * 0.2f
                sparks +=
                    Spark(
                        item.center.copyOf(),
                        floatArrayOf(cos(angle) * 0.7f, rise, sin(angle) * 0.7f),
                        sparkColors[index % sparkColors.size],
                    )
            }
        }
    }

    private fun send(method: String, arguments: Any?) {
        main.post { if (!disposed) channel.invokeMethod(method, arguments) }
    }

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        renderer.create()
        session?.setCameraTextureName(renderer.cameraTexture)
        meshes =
            modelArgs.entries.associate { (kind, model) ->
                kind as String to ArModelMesh.upload(model as Map<*, *>)
            }
        sparkMesh = ArMesh.sparkShape()
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
        viewportWidth = width
        viewportHeight = height
        geometryPending = true
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        val current = session ?: return
        if (!active) return
        if (geometryPending) {
            @Suppress("DEPRECATION")
            current.setDisplayGeometry(
                activity.windowManager.defaultDisplay.rotation,
                viewportWidth,
                viewportHeight,
            )
            geometryPending = false
        }
        current.setCameraTextureName(renderer.cameraTexture)
        val frame =
            try {
                current.update()
            } catch (_: SessionPausedException) {
                return
            } catch (_: CameraNotAvailableException) {
                send("onError", mapOf("code" to "camera_unavailable"))
                return
            }
        renderer.drawCamera(frame)

        val camera = frame.camera
        reportTracking(camera)
        // Items are hidden until tracking returns, so they never jump around.
        if (camera.trackingState != TrackingState.TRACKING) {
            taps.clear()
            return
        }
        pendingOrigin?.let {
            origin = current.createAnchor(it)
            pendingOrigin = null
        }
        reportPosters(frame, camera)

        val now = System.nanoTime()
        val dt = if (lastFrameNanos == 0L) 0f else (now - lastFrameNanos) / 1e9f
        lastFrameNanos = now
        // Wrapped, because a Float cannot hold a long uptime precisely.
        val time = (now % TIME_WRAP_NANOS) / 1e9f

        camera.getViewMatrix(viewMatrix, 0)
        camera.getProjectionMatrix(projectionMatrix, 0, NEAR, FAR)
        Matrix.multiplyMM(viewProjection, 0, projectionMatrix, 0, viewMatrix, 0)
        val ambient = 0.35f + 0.65f * frame.lightEstimate.pixelIntensity.coerceIn(0f, 1f)

        val originPose = origin?.pose
        if (originPose != null) {
            positionItems(current, originPose, camera.pose.translation)
            checkSight(frame, now)
            reportNearest(camera, now)
            handleTaps(frame, camera, originPose)
            val originFront = originPose.zAxis
            drawItems(atan2(originFront[0], originFront[2]), time, ambient, now)
        } else {
            taps.clear()
        }
        drawSparks(dt)
    }

    private fun positionItems(session: Session, originPose: Pose, camera: FloatArray) {
        for (item in items) {
            val pin = item.pin
            val world =
                if (pin != null && pin.trackingState == TrackingState.TRACKING) {
                    pin.pose.translation
                } else {
                    originPose.transformPoint(item.local)
                }
            val height = meshes[item.kind]?.height ?: 0f
            item.center = floatArrayOf(world[0], world[1] + height * item.scale / 2, world[2])
            val dx = camera[0] - world[0]
            val dy = camera[1] - world[1]
            val dz = camera[2] - world[2]
            item.distance = sqrt(dx * dx + dy * dy + dz * dz)
            if (!placing && pin == null && item.distance <= visibleRadius) pinItem(session, item, world)
        }
    }

    /**
     * Once a player is close, ARCore has mapped the room around the item, so an
     * anchor of its own there holds it to the room better than one at the poster.
     */
    private fun pinItem(session: Session, item: SceneItem, world: FloatArray) {
        try {
            item.pin = session.createAnchor(Pose.makeTranslation(world))
        } catch (error: Exception) {
            // It simply stays relative to the poster's anchor.
            Log.w(TAG, "Could not anchor an item", error)
        }
    }

    /** Looks along the view of each item on screen for the nearest real surface. */
    private fun checkSight(frame: Frame, now: Long) {
        if (now - lastSightCheckNanos < SIGHT_CHECK_NANOS) return
        lastSightCheckNanos = now
        val clip = FloatArray(4)
        for (item in items) {
            if (item.distance > visibleRadius) continue
            Matrix.multiplyMV(clip, 0, viewProjection, 0, floatArrayOf(item.center[0], item.center[1], item.center[2], 1f), 0)
            if (clip[3] <= 0 || abs(clip[0] / clip[3]) > 1 || abs(clip[1] / clip[3]) > 1) continue
            val x = (clip[0] / clip[3] + 1) / 2 * viewportWidth
            val y = (1 - clip[1] / clip[3]) / 2 * viewportHeight
            val nearest =
                frame.hitTest(x, y)
                    .filter { hit ->
                        val trackable = hit.trackable
                        trackable is DepthPoint ||
                            (trackable is Plane && trackable.isPoseInPolygon(hit.hitPose)) ||
                            (trackable is Point && trackable.orientationMode == Point.OrientationMode.ESTIMATED_SURFACE_NORMAL)
                    }.minOfOrNull { it.distance }
            item.sight.update(nearest, item.distance, now)
        }
    }

    private fun drawItems(originYaw: Float, time: Float, ambient: Float, now: Long) {
        for (item in items) {
            if (item.distance > visibleRadius || !item.sight.isShown(item.distance, now)) continue
            val model = meshes[item.kind] ?: continue
            val size = smoothstep((visibleRadius - item.distance) / APPEAR_DISTANCE) * item.scale
            val baseY = item.center[1] - model.height * item.scale / 2
            val yaw = originYaw + item.yaw
            Matrix.setIdentityM(itemMatrix, 0)
            Matrix.translateM(itemMatrix, 0, item.center[0], baseY, item.center[2])
            Matrix.rotateM(itemMatrix, 0, Math.toDegrees(yaw.toDouble()).toFloat(), 0f, 1f, 0f)
            Matrix.scaleM(itemMatrix, 0, size, size, size)

            val flicker = if (reduceMotion) 1f else 1f + 0.08f * sin(11f * time + item.phase) + 0.04f * sin(17f * time)
            // Solid parts first, so the glow blends over them.
            for (pass in 0..1) {
                for (part in model.parts) {
                    if (part.translucent != (pass == 1)) continue
                    System.arraycopy(itemMatrix, 0, partMatrix, 0, 16)
                    if (part.flicker) {
                        Matrix.translateM(partMatrix, 0, part.pivot[0], part.pivot[1], part.pivot[2])
                        Matrix.scaleM(partMatrix, 0, 1 + (1 - flicker) / 2, flicker, 1 + (1 - flicker) / 2)
                        Matrix.translateM(partMatrix, 0, -part.pivot[0], -part.pivot[1], -part.pivot[2])
                    }
                    Matrix.multiplyMM(mvp, 0, viewProjection, 0, partMatrix, 0)
                    renderer.drawMesh(part, mvp, partMatrix, ambient)
                }
            }
        }
    }

    private fun drawSparks(dt: Float) {
        if (sparks.isEmpty()) return
        val shape = sparkMesh ?: return
        val iterator = sparks.iterator()
        while (iterator.hasNext()) {
            val spark = iterator.next()
            spark.age += dt
            if (spark.age >= SPARK_LIFE) {
                iterator.remove()
                continue
            }
            spark.velocity[1] -= 1.6f * dt
            for (axis in 0..2) spark.position[axis] += spark.velocity[axis] * dt
            val size = 0.02f * (1 - spark.age / SPARK_LIFE)
            Matrix.setIdentityM(partMatrix, 0)
            Matrix.translateM(partMatrix, 0, spark.position[0], spark.position[1], spark.position[2])
            Matrix.scaleM(partMatrix, 0, size, size, size)
            Matrix.multiplyMM(mvp, 0, viewProjection, 0, partMatrix, 0)
            shape.rgba = spark.rgba
            renderer.drawMesh(shape, mvp, partMatrix, 1f)
        }
    }

    private fun handleTaps(frame: Frame, camera: Camera, originPose: Pose) {
        while (true) {
            val tap = taps.poll() ?: return
            val picked = pick(tap)
            when {
                picked != null ->
                    send("onItemTap", mapOf("id" to picked.id, "distance" to picked.distance.toDouble()))
                placing -> reportSurface(frame, camera, originPose, tap)
            }
        }
    }

    private fun isOnScreen(item: SceneItem): Boolean {
        val clip = FloatArray(4)
        Matrix.multiplyMV(clip, 0, viewProjection, 0, floatArrayOf(item.center[0], item.center[1], item.center[2], 1f), 0)
        return clip[3] > 0 && abs(clip[0] / clip[3]) <= 1 && abs(clip[1] / clip[3]) <= 1
    }

    /** The drawn item nearest the finger, generously, as items are small. */
    private fun pick(tap: FloatArray): SceneItem? {
        var best: SceneItem? = null
        var bestDistance = pickRadius
        val clip = FloatArray(4)
        val now = System.nanoTime()
        for (item in items) {
            if (item.distance > visibleRadius || !item.sight.isShown(item.distance, now)) continue
            val center = floatArrayOf(item.center[0], item.center[1], item.center[2], 1f)
            Matrix.multiplyMV(clip, 0, viewProjection, 0, center, 0)
            if (clip[3] <= 0) continue
            val x = (clip[0] / clip[3] + 1) / 2 * viewportWidth
            val y = (1 - clip[1] / clip[3]) / 2 * viewportHeight
            val distance = sqrt((x - tap[0]) * (x - tap[0]) + (y - tap[1]) * (y - tap[1]))
            if (distance < bestDistance) {
                best = item
                bestDistance = distance
            }
        }
        return best
    }

    private fun reportSurface(frame: Frame, camera: Camera, originPose: Pose, tap: FloatArray) {
        val hit =
            frame.hitTest(tap[0], tap[1]).firstOrNull {
                val trackable = it.trackable
                // Tracked points and depth count too, so things with no flat
                // surface, like the side of a computer, can hold an item.
                trackable is Point ||
                    trackable is DepthPoint ||
                    (trackable is Plane && trackable.isPoseInPolygon(it.hitPose))
            }
        val world: FloatArray
        if (hit != null) {
            val normal = hit.hitPose.yAxis
            world = hit.hitPose.translation
            // On a wall, stand the item off it instead of half inside it.
            if (abs(normal[1]) < 0.7f) {
                for (axis in 0..2) world[axis] += normal[axis] * WALL_OFFSET
            }
        } else {
            world = pointAhead(camera, tap)
        }
        val local = originPose.inverse().transformPoint(world)
        send(
            "onSurfaceTap",
            mapOf(
                "x" to local[0].toDouble(),
                "y" to local[1].toDouble(),
                "z" to local[2].toDouble(),
                "onSurface" to (hit != null),
            ),
        )
    }

    /** No surface there, so use a spot along the ray under the finger. */
    private fun pointAhead(camera: Camera, tap: FloatArray): FloatArray {
        val inverse = FloatArray(16)
        Matrix.invertM(inverse, 0, viewProjection, 0)
        val far = FloatArray(4)
        Matrix.multiplyMV(
            far,
            0,
            inverse,
            0,
            floatArrayOf(2 * tap[0] / viewportWidth - 1, 1 - 2 * tap[1] / viewportHeight, 1f, 1f),
            0,
        )
        val start = camera.pose.translation
        val direction = FloatArray(3) { far[it] / far[3] - start[it] }
        val length = sqrt(direction[0] * direction[0] + direction[1] * direction[1] + direction[2] * direction[2])
        return FloatArray(3) { start[it] + direction[it] / length * FLOATING_DISTANCE }
    }

    private fun reportTracking(camera: Camera) {
        val state =
            if (camera.trackingState == TrackingState.TRACKING) {
                "normal"
            } else {
                when (camera.trackingFailureReason) {
                    TrackingFailureReason.NONE -> "initializing"
                    TrackingFailureReason.INSUFFICIENT_LIGHT -> "tooDark"
                    TrackingFailureReason.EXCESSIVE_MOTION -> "tooFast"
                    TrackingFailureReason.INSUFFICIENT_FEATURES -> "lowDetail"
                    else -> "unavailable"
                }
            }
        if (state != lastTracking) {
            lastTracking = state
            send("onTracking", mapOf("state" to state))
        }
    }

    private fun reportPosters(frame: Frame, camera: Camera) {
        val now = System.nanoTime()
        if (now - lastPosterNanos < POSTER_INTERVAL_NANOS) return
        for (image in frame.getUpdatedTrackables(AugmentedImage::class.java)) {
            if (image.trackingState != TrackingState.TRACKING ||
                image.trackingMethod != AugmentedImage.TrackingMethod.FULL_TRACKING
            ) {
                continue
            }
            lastPosterNanos = now
            val pose = FloatArray(16)
            image.centerPose.toMatrix(pose, 0)
            send(
                "onPoster",
                mapOf(
                    "id" to image.name,
                    "pose" to pose.map(Float::toDouble),
                    "camera" to camera.pose.translation.map(Float::toDouble),
                ),
            )
            return
        }
    }

    private fun reportNearest(camera: Camera, now: Long) {
        if (placing || now - lastNearestNanos < NEAREST_INTERVAL_NANOS) return
        val nearest = items.minByOrNull { it.distance } ?: return
        lastNearestNanos = now
        val local = camera.pose.inverse().transformPoint(nearest.center)
        send(
            "onNearest",
            mapOf(
                "id" to nearest.id,
                "distance" to nearest.distance.toDouble(),
                "bearing" to atan2(local[0], -local[2]).toDouble(),
                "onScreen" to (nearest.distance <= visibleRadius && nearest.sight.isShown(nearest.distance, now) && isOnScreen(nearest)),
            ),
        )
    }

    private companion object {
        const val TAG = "ArHuntView"
        const val NEAR = 0.05f
        const val FAR = 100f
        const val APPEAR_DISTANCE = 1f
        const val WALL_OFFSET = 0.06f
        const val SIGHT_CHECK_NANOS = 250_000_000L
        const val FLOATING_DISTANCE = 1.2f
        const val SPARK_COUNT = 18
        const val SPARK_LIFE = 0.8f
        const val TIME_WRAP_NANOS = 1_000_000_000_000L
        const val POSTER_INTERVAL_NANOS = 66_000_000L
        const val NEAREST_INTERVAL_NANOS = 500_000_000L

        fun smoothstep(value: Float): Float {
            val t = value.coerceIn(0f, 1f)
            return t * t * (3 - 2 * t)
        }
    }
}
