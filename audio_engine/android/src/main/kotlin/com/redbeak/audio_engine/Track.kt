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
        val renderersFactory = CustomRenderersFactory(context, panProcessor)

        player = ExoPlayer.Builder(context)
            .setRenderersFactory(renderersFactory)
            .build()

        player.setMediaItem(MediaItem.fromUri(uri))
        player.prepare()
        applyParams()
    }

    private fun applyParams() {
        player.playbackParameters = PlaybackParameters(speed, pitch)
    }

    fun setSpeed(v: Float) {
        speed = v; applyParams()
    }

    fun setPitch(v: Float) {
        pitch = v; applyParams()
    }

    fun setPan(v: Float) {
        panProcessor.pan = v.coerceIn(-1f, 1f)
    }

    fun setGain(v: Float) {
        player.volume = v.coerceIn(0f, 1f)
    }

    fun start(offsetMs: Long) {
        player.seekTo(offsetMs); player.playWhenReady = true
    }

    fun stop() {
        player.stop()
    }

    fun pause() {
        player.playWhenReady = false
    }

    fun release() {
        player.release()
    }
}

class CustomRenderersFactory(
    context: Context,
    private val panProcessor: AudioProcessor
) : DefaultRenderersFactory(context) {

    override fun buildAudioSink(
        context: Context,
        enableFloatOutput: Boolean,
        enableAudioTrackPlaybackParams: Boolean,
        offloadMode: Boolean
    ): DefaultAudioSink {
        return DefaultAudioSink.Builder()
            .setEnableFloatOutput(enableFloatOutput)
            .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
            .setAudioProcessors(arrayOf(panProcessor))
            .build()
    }
}
