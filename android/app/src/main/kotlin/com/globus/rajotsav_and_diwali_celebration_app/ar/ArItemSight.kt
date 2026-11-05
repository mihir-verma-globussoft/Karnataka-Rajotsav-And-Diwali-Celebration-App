package com.globus.rajotsav_and_diwali_celebration_app.ar

/**
 * Whether to show an item, going by what the phone can tell about the surfaces
 * on the way to it. Most phones cannot see a plain wall at all, so an item that
 * is not right next to the player stays hidden until a clear view is confirmed.
 * Once seen it stays shown until a surface is in front of it twice in a row, so
 * one noisy reading never makes it blink.
 * Same rule as `ArItemSight` in ios/Runner/Ar/ArHuntView.swift.
 */
internal class ArItemSight(private var clear: Boolean = false) {
    private var blockedReadings = 0
    private var blockedUntil = 0L

    /** [nearestSurface] is in metres along the view of the item; null if none was found. */
    fun update(nearestSurface: Float?, itemDistance: Float, now: Long) {
        if (nearestSurface == null) return
        if (nearestSurface >= itemDistance - MARGIN) {
            blockedReadings = 0
            if (blockedUntil <= now) clear = true
            return
        }
        blockedReadings++
        if (blockedReadings >= BLOCKED_READINGS) {
            clear = false
            blockedUntil = now + HOLD_NANOS
        }
    }

    fun isShown(itemDistance: Float, now: Long) =
        blockedUntil <= now && (clear || itemDistance <= CLOSE_ENOUGH)

    private companion object {
        /** A surface must be this much nearer than the item to count as in front. */
        const val MARGIN = 0.3f

        /** This close, the player is almost certainly in the same room. */
        const val CLOSE_ENOUGH = 1.5f

        const val BLOCKED_READINGS = 2

        /** Stays hidden at least this long once blocked, so it never flickers. */
        const val HOLD_NANOS = 1_000_000_000L
    }
}
