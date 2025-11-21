package com.redbeak.audio_engine

import android.content.Context
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

class Engine(context: Context) {
  private val appCtx = context.applicationContext
  private val idGen = AtomicInteger(1)
  private val tracks = ConcurrentHashMap<Int, Track>()

  fun createTrack(uri: String): Int {
    val id = idGen.getAndIncrement()
    tracks[id] = Track(appCtx, uri)
    return id
  }

  fun disposeTrack(id: Int) { tracks.remove(id)?.release() }

  fun setGain(id: Int, v: Double)  { tracks[id]?.setGain(v.toFloat()) }
  fun setSpeed(id: Int, v: Double) { tracks[id]?.setSpeed(v.toFloat()) }
  fun setPitch(id: Int, v: Double) { tracks[id]?.setPitch(v.toFloat()) }
  fun setPan(id: Int, v: Double)   { tracks[id]?.setPan(v.toFloat()) }

  fun start(id: Int, offsetMs: Long) { tracks[id]?.start(offsetMs) }
  fun stop(id: Int) { tracks[id]?.stop() }

  fun startAll(offsets: Map<Int, Long>) {
    // Simple sync: seek all, then play all in same loop
    offsets.forEach { (id, ms) -> tracks[id]?.start(ms) }
  }
  fun stopAll() { tracks.values.forEach { it.stop() } }

  fun release() { tracks.values.forEach { it.release() }; tracks.clear() }
}