package com.redbeak.audio_engine

import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.audio.BaseAudioProcessor
import com.google.android.exoplayer2.audio.AudioProcessor.AudioFormat
import java.nio.ByteBuffer
import kotlin.math.cos
import kotlin.math.sin

class PanAudioProcessor : BaseAudioProcessor() {
  @Volatile var pan: Float = 0f // -1..+1

  override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat {
    // Act only on stereo float PCM; otherwise pass-through
    return if (inputAudioFormat.encoding == C.ENCODING_PCM_FLOAT &&
               inputAudioFormat.channelCount == 2) inputAudioFormat else inputAudioFormat
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    val out = replaceOutputBuffer(inputBuffer.remaining())
    val angle = ((pan + 1f) * 0.25f * Math.PI).toFloat() // 0..π/2
    val gL = cos(angle)
    val gR = sin(angle)
    while (inputBuffer.hasRemaining()) {
      val l = inputBuffer.getFloat()
      val r = inputBuffer.getFloat()
      out.putFloat((l * gL).toFloat())
      out.putFloat((r * gR).toFloat())
    }
    inputBuffer.position(inputBuffer.limit())
    out.flip()
  }
}