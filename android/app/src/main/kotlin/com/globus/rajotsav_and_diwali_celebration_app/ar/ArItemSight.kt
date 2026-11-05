package com.globus.rajotsav_and_diwali_celebration_app.ar

/**
 * Whether to show an item, going by what the phone can tell about the surfaces
 * on the way to it.
 *
 * Shown by default, and after any hold expires: a hit test that finds nothing
 * is the ordinary case (a blank wall, dim corner, or a spot ARCore has not
 * mapped yet), not evidence that something is blocking the item, so it must
 * never be read as one. Only a surface the phone actually tracked, confirmed
 * strictly nearer than the item twice in a row, hides it; a single clear
 * reading afterwards (or simply no fresh blocking reading before the hold
 * runs out) shows it again.
 * Same rule as `ArItemSight` in ios/Runner/Ar/ArHuntView.swift.
 */
internal class ArItemSight {
    private var blockedReadings = 0
    private var blockedUntil = 0L

    /** [nearestSurface] is in metres along the view of the item; null if none was found. */
    fun update(nearestSurface: Float?, itemDistance: Float, now: Long) {
        if (nearestSurface == null) return
        if (nearestSurface >= itemDistance - MARGIN) {
            blockedReadings = 0
            blockedUntil = 0
            return
        }
        blockedReadings++
        if (blockedReadings >= BLOCKED_READINGS) {
            blockedUntil = now + HOLD_NANOS
        }
    }

    fun isShown(now: Long) = blockedUntil <= now

    private companion object {
        /** A surface must be this much nearer than the item to count as in front. */
        const val MARGIN = 0.3f

        const val BLOCKED_READINGS = 2

        /** Stays hidden at most this long without a fresh blocking reading. */
        const val HOLD_NANOS = 1_000_000_000L
    }
}
