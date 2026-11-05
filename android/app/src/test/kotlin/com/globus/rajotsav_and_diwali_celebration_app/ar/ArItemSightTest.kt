package com.globus.rajotsav_and_diwali_celebration_app.ar

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Same cases as ArItemSightTests in ios/RunnerTests, so both phones agree. */
class ArItemSightTest {
    private val far = 3f
    private val close = 1f
    private val second = 1_000_000_000L

    @Test
    fun `an item across the room stays hidden until a clear view is confirmed`() {
        val sight = ArItemSight()
        assertFalse(sight.isShown(far, 0))
        sight.update(null, far, 0)
        assertFalse("a plain wall gives no surface at all", sight.isShown(far, 0))
    }

    @Test
    fun `seeing the surface the item rests on shows it`() {
        val sight = ArItemSight()
        sight.update(far, far, 0)
        assertTrue(sight.isShown(far, 0))
    }

    @Test
    fun `seeing a surface beyond the item shows it`() {
        val sight = ArItemSight()
        sight.update(far + 2, far, 0)
        assertTrue(sight.isShown(far, 0))
    }

    @Test
    fun `a table or wall in front hides it, even close up`() {
        val sight = ArItemSight()
        sight.update(close - 0.5f, close, 0)
        sight.update(close - 0.5f, close, second / 4)
        assertFalse(sight.isShown(close, second / 4))
    }

    @Test
    fun `one odd reading does not hide it`() {
        val sight = ArItemSight()
        sight.update(far, far, 0)
        sight.update(1f, far, second / 4)
        assertTrue(sight.isShown(far, second / 4))
    }

    @Test
    fun `a surface only just in front is the one it stands on`() {
        val sight = ArItemSight()
        sight.update(far - 0.2f, far, 0)
        assertTrue(sight.isShown(far, 0))
    }

    @Test
    fun `right next to an item it shows without being confirmed`() {
        assertTrue(ArItemSight().isShown(close, 0))
    }

    @Test
    fun `once seen, it stays shown while the phone has no answer`() {
        val sight = ArItemSight()
        sight.update(far, far, 0)
        sight.update(null, far, 5 * second)
        assertTrue("no blinking between checks", sight.isShown(far, 5 * second))
    }

    @Test
    fun `after being hidden, it needs a clear view again`() {
        val sight = ArItemSight()
        sight.update(far, far, 0)
        sight.update(1f, far, second / 4)
        sight.update(1f, far, second / 2)
        assertFalse(sight.isShown(far, 3 * second))
        sight.update(far, far, 3 * second)
        assertTrue(sight.isShown(far, 3 * second))
    }

    @Test
    fun `the organiser's items start shown`() {
        assertTrue(ArItemSight(clear = true).isShown(far, 0))
    }
}
