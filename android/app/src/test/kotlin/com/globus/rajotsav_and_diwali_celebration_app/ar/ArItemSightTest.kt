package com.globus.rajotsav_and_diwali_celebration_app.ar

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Same cases as ArItemSightTests in ios/RunnerTests, so both phones agree.
 *
 * The rule is "shown unless blocked", not "shown only once confirmed clear":
 * a hit test that finds nothing is the normal case on a blank wall, dim
 * corner or a spot ARCore/ARKit has not mapped yet, and must never be read
 * as "there is a wall here." Only a surface the phone actually tracked,
 * strictly nearer than the item, counts as blocking it.
 */
class ArItemSightTest {
    private val far = 3f
    private val close = 1f
    private val second = 1_000_000_000L

    @Test
    fun `an item is shown from the start, with no reading at all`() {
        assertTrue(ArItemSight().isShown(0))
    }

    @Test
    fun `a hit test that finds nothing changes nothing`() {
        val sight = ArItemSight()
        sight.update(null, far, 0)
        assertTrue("no data is not evidence of a wall", sight.isShown(0))
    }

    @Test
    fun `seeing the surface the item rests on keeps it shown`() {
        val sight = ArItemSight()
        sight.update(far, far, 0)
        assertTrue(sight.isShown(0))
    }

    @Test
    fun `seeing a surface beyond the item keeps it shown`() {
        val sight = ArItemSight()
        sight.update(far + 2, far, 0)
        assertTrue(sight.isShown(0))
    }

    @Test
    fun `a tracked surface in front hides it, even close up`() {
        val sight = ArItemSight()
        sight.update(close - 0.5f, close, 0)
        sight.update(close - 0.5f, close, second / 4)
        assertFalse(sight.isShown(second / 4))
    }

    @Test
    fun `one odd reading does not hide it`() {
        val sight = ArItemSight()
        sight.update(far, far, 0)
        sight.update(1f, far, second / 4)
        assertTrue(sight.isShown(second / 4))
    }

    @Test
    fun `a surface only just in front is the one it stands on`() {
        val sight = ArItemSight()
        sight.update(far - 0.2f, far, 0)
        assertTrue(sight.isShown(0))
    }

    @Test
    fun `once hidden, a clear reading shows it again`() {
        val sight = ArItemSight()
        sight.update(1f, far, 0)
        sight.update(1f, far, second / 4)
        assertFalse(sight.isShown(second / 2))
        sight.update(far, far, second / 2)
        assertTrue(sight.isShown(second / 2))
    }

    @Test
    fun `once hidden, a sustained run with no reading also shows it again`() {
        val sight = ArItemSight()
        sight.update(1f, far, 0)
        sight.update(1f, far, second / 4)
        assertFalse(sight.isShown(second / 2))
        // No hit test lands for a while: that is not "still blocked".
        assertTrue("no data must not hide something forever", sight.isShown(10 * second))
    }

    @Test
    fun `being blocked is remembered for a short hold, so it never flickers`() {
        val sight = ArItemSight()
        sight.update(1f, far, 0)
        sight.update(1f, far, second / 4)
        assertFalse(sight.isShown(second / 4 + 1))
    }
}
