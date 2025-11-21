package com.redbeak.audio_engine

import android.content.Context
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackParameters
import com.google.android.exoplayer2.audio.AudioProcessor
import com.google.android.exoplayer2.audio.DefaultAudioSink
import com.google.android.exoplayer2.DefaultRenderersFactory

class Track(context: Context, uri: String) {
  private val panProcessor = PanAudioProcessor()
  private val player: ExoPlayer
  private var speed = 1f
  private var pitch = 1f

  init {
    val renderersFactory = DefaultRenderersFactory(context)
      .setEnableAudioFloatOutput(true)
      .setAudioSinkSupplier { _, _, _, _, _ ->
        DefaultAudioSink.Builder()
          .setEnableFloatOutput(true) // fallbacks internally to 16-bit if needed
          .setAudioProcessors(arrayOf<AudioProcessor>(panProcessor))
          .build()
      }

    player = ExoPlayer.Builder(context, renderersFactory).build()
    player.setMediaItem(MediaItem.fromUri(uri)) // file://... or content://...
    player.prepare()
    applyParams()
  }

  private fun applyParams() {
    player.playbackParameters = PlaybackParameters(speed, pitch)
  }

  fun setSpeed(v: Float) { speed = v; applyParams() }
  fun setPitch(v: Float) { pitch = v; applyParams() }
  fun setPan(v: Float)   { panProcessor.pan = v.coerceIn(-1f, 1f) }
  fun setGain(v: Float)  { player.volume = v.coerceIn(0f, 1f) }

  fun start(offsetMs: Long) { player.seekTo(offsetMs); player.playWhenReady = true }
  fun stop() { player.stop() }
  fun pause() { player.playWhenReady = false }
  fun release() { player.release() }
}