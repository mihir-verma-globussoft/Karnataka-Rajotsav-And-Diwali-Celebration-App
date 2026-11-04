package com.globus.rajotsav_and_diwali_celebration_app.ar

import android.opengl.GLES11Ext
import android.opengl.GLES20
import com.google.ar.core.Coordinates2d
import com.google.ar.core.Frame
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

internal fun rgbaOf(argb: Number): FloatArray {
    val value = argb.toLong()
    return floatArrayOf(
        ((value shr 16) and 0xFF) / 255f,
        ((value shr 8) and 0xFF) / 255f,
        (value and 0xFF) / 255f,
        ((value shr 24) and 0xFF) / 255f,
    )
}

private fun floatBuffer(values: FloatArray): FloatBuffer =
    ByteBuffer
        .allocateDirect(values.size * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(values)
            position(0)
        }

/** One part of a model, on the GPU. */
internal class ArMesh(
    positions: FloatArray,
    normals: FloatArray,
    indices: IntArray,
    var rgba: FloatArray,
    val unlit: Boolean,
    val flicker: Boolean,
    val pivot: FloatArray,
) {
    val count = indices.size
    val translucent = rgba[3] < 1f
    val positionBuffer: Int
    val normalBuffer: Int
    val indexBuffer: Int

    init {
        val ids = IntArray(3)
        GLES20.glGenBuffers(3, ids, 0)
        positionBuffer = ids[0]
        normalBuffer = ids[1]
        indexBuffer = ids[2]
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, positionBuffer)
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, positions.size * 4, floatBuffer(positions), GLES20.GL_STATIC_DRAW)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, normalBuffer)
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, normals.size * 4, floatBuffer(normals), GLES20.GL_STATIC_DRAW)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)
        val shorts =
            ByteBuffer
                .allocateDirect(indices.size * 2)
                .order(ByteOrder.nativeOrder())
                .asShortBuffer()
        for (index in indices) shorts.put(index.toShort())
        shorts.position(0)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, indexBuffer)
        GLES20.glBufferData(GLES20.GL_ELEMENT_ARRAY_BUFFER, indices.size * 2, shorts, GLES20.GL_STATIC_DRAW)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, 0)
    }

    companion object {
        /** A small diamond: seen from a distance, sparks need no more than this. */
        fun sparkShape(): ArMesh {
            val positions = floatArrayOf(1f, 0f, 0f, -1f, 0f, 0f, 0f, 1f, 0f, 0f, -1f, 0f, 0f, 0f, 1f, 0f, 0f, -1f)
            return ArMesh(
                positions,
                positions,
                intArrayOf(0, 2, 4, 2, 1, 4, 1, 3, 4, 3, 0, 4, 2, 0, 5, 1, 2, 5, 3, 1, 5, 0, 3, 5),
                floatArrayOf(1f, 1f, 1f, 1f),
                unlit = true,
                flicker = false,
                pivot = FloatArray(3),
            )
        }
    }
}

internal class ArModelMesh(
    val height: Float,
    val parts: List<ArMesh>,
) {
    companion object {
        /** Reads the shape built by `ArModel.toWire()` in Dart. */
        fun upload(model: Map<*, *>): ArModelMesh =
            ArModelMesh(
                (model["height"] as Number).toFloat(),
                (model["parts"] as List<*>).map { raw ->
                    val part = raw as Map<*, *>
                    ArMesh(
                        part["positions"] as FloatArray,
                        part["normals"] as FloatArray,
                        part["indices"] as IntArray,
                        rgbaOf(part["argb"] as Number),
                        part["unlit"] as Boolean,
                        part["flicker"] as Boolean,
                        (part["pivot"] as List<*>).map { (it as Number).toFloat() }.toFloatArray(),
                    )
                },
            )
    }
}

/** The two shaders the hunt draws with: the camera image, and the models. */
internal class ArGlPrograms {
    var cameraTexture = 0
        private set
    private var cameraProgram = 0
    private var cameraPosition = 0
    private var cameraUv = 0
    private var meshProgram = 0
    private var meshPosition = 0
    private var meshNormal = 0
    private var meshMvp = 0
    private var meshModel = 0
    private var meshColor = 0
    private var meshUnlit = 0
    private var meshAmbient = 0
    private val quad = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
    private val quadBuffer = floatBuffer(quad)
    private val uvBuffer = floatBuffer(FloatArray(8))

    fun create() {
        val ids = IntArray(1)
        GLES20.glGenTextures(1, ids, 0)
        cameraTexture = ids[0]
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTexture)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)

        cameraProgram = program(CAMERA_VERTEX, CAMERA_FRAGMENT)
        cameraPosition = GLES20.glGetAttribLocation(cameraProgram, "a_position")
        cameraUv = GLES20.glGetAttribLocation(cameraProgram, "a_uv")

        meshProgram = program(MESH_VERTEX, MESH_FRAGMENT)
        meshPosition = GLES20.glGetAttribLocation(meshProgram, "a_position")
        meshNormal = GLES20.glGetAttribLocation(meshProgram, "a_normal")
        meshMvp = GLES20.glGetUniformLocation(meshProgram, "u_mvp")
        meshModel = GLES20.glGetUniformLocation(meshProgram, "u_model")
        meshColor = GLES20.glGetUniformLocation(meshProgram, "u_color")
        meshUnlit = GLES20.glGetUniformLocation(meshProgram, "u_unlit")
        meshAmbient = GLES20.glGetUniformLocation(meshProgram, "u_ambient")
    }

    fun drawCamera(frame: Frame) {
        if (frame.hasDisplayGeometryChanged()) {
            frame.transformCoordinates2d(
                Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES,
                quadBuffer,
                Coordinates2d.TEXTURE_NORMALIZED,
                uvBuffer,
            )
            quadBuffer.position(0)
            uvBuffer.position(0)
        }
        if (frame.timestamp == 0L) return
        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glDepthMask(false)
        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glUseProgram(cameraProgram)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTexture)
        GLES20.glEnableVertexAttribArray(cameraPosition)
        GLES20.glEnableVertexAttribArray(cameraUv)
        GLES20.glVertexAttribPointer(cameraPosition, 2, GLES20.GL_FLOAT, false, 0, quadBuffer)
        GLES20.glVertexAttribPointer(cameraUv, 2, GLES20.GL_FLOAT, false, 0, uvBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(cameraPosition)
        GLES20.glDisableVertexAttribArray(cameraUv)
        GLES20.glDepthMask(true)
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
    }

    fun drawMesh(mesh: ArMesh, mvp: FloatArray, model: FloatArray, ambient: Float) {
        GLES20.glUseProgram(meshProgram)
        if (mesh.translucent) {
            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_ALPHA)
            GLES20.glDepthMask(false)
        } else {
            GLES20.glDisable(GLES20.GL_BLEND)
            GLES20.glDepthMask(true)
        }
        GLES20.glUniformMatrix4fv(meshMvp, 1, false, mvp, 0)
        GLES20.glUniformMatrix4fv(meshModel, 1, false, model, 0)
        GLES20.glUniform4fv(meshColor, 1, mesh.rgba, 0)
        GLES20.glUniform1f(meshUnlit, if (mesh.unlit) 1f else 0f)
        GLES20.glUniform1f(meshAmbient, ambient)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, mesh.positionBuffer)
        GLES20.glEnableVertexAttribArray(meshPosition)
        GLES20.glVertexAttribPointer(meshPosition, 3, GLES20.GL_FLOAT, false, 0, 0)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, mesh.normalBuffer)
        GLES20.glEnableVertexAttribArray(meshNormal)
        GLES20.glVertexAttribPointer(meshNormal, 3, GLES20.GL_FLOAT, false, 0, 0)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, mesh.indexBuffer)
        GLES20.glDrawElements(GLES20.GL_TRIANGLES, mesh.count, GLES20.GL_UNSIGNED_SHORT, 0)
        GLES20.glDisableVertexAttribArray(meshPosition)
        GLES20.glDisableVertexAttribArray(meshNormal)
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0)
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, 0)
        GLES20.glDepthMask(true)
    }

    private fun program(vertex: String, fragment: String): Int {
        val id = GLES20.glCreateProgram()
        GLES20.glAttachShader(id, shader(GLES20.GL_VERTEX_SHADER, vertex))
        GLES20.glAttachShader(id, shader(GLES20.GL_FRAGMENT_SHADER, fragment))
        GLES20.glLinkProgram(id)
        return id
    }

    private fun shader(type: Int, source: String): Int {
        val id = GLES20.glCreateShader(type)
        GLES20.glShaderSource(id, source)
        GLES20.glCompileShader(id)
        val status = IntArray(1)
        GLES20.glGetShaderiv(id, GLES20.GL_COMPILE_STATUS, status, 0)
        check(status[0] != 0) { GLES20.glGetShaderInfoLog(id) }
        return id
    }

    private companion object {
        const val CAMERA_VERTEX = """
            attribute vec4 a_position;
            attribute vec2 a_uv;
            varying vec2 v_uv;
            void main() {
              gl_Position = a_position;
              v_uv = a_uv;
            }
        """
        const val CAMERA_FRAGMENT = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 v_uv;
            uniform samplerExternalOES u_texture;
            void main() {
              gl_FragColor = texture2D(u_texture, v_uv);
            }
        """
        const val MESH_VERTEX = """
            attribute vec3 a_position;
            attribute vec3 a_normal;
            uniform mat4 u_mvp;
            uniform mat4 u_model;
            varying vec3 v_normal;
            void main() {
              v_normal = (u_model * vec4(a_normal, 0.0)).xyz;
              gl_Position = u_mvp * vec4(a_position, 1.0);
            }
        """
        const val MESH_FRAGMENT = """
            precision mediump float;
            uniform vec4 u_color;
            uniform float u_unlit;
            uniform float u_ambient;
            varying vec3 v_normal;
            void main() {
              if (u_unlit > 0.5) {
                gl_FragColor = vec4(u_color.rgb * u_color.a, u_color.a);
              } else {
                float light = max(dot(normalize(v_normal), normalize(vec3(0.3, 1.0, 0.5))), 0.0);
                gl_FragColor = vec4(u_color.rgb * (u_ambient * 0.6 + light * 0.6), 1.0);
              }
            }
        """
    }
}
