package com.redbeak.audio_engine

import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.audio.AudioProcessor.AudioFormat
import com.google.android.exoplayer2.audio.BaseAudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.cos
import kotlin.math.sin

class PanAudioProcessor : BaseAudioProcessor() {

    @Volatile
    var pan: Float = 0f

    private var pendingLeft: Float? = null

    override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat {
        return if (
            (inputAudioFormat.encoding == C.ENCODING_PCM_16BIT ||
                    inputAudioFormat.encoding == C.ENCODING_PCM_FLOAT) &&
            inputAudioFormat.channelCount == 2
        ) {
            AudioFormat(
                inputAudioFormat.sampleRate,
                inputAudioFormat.channelCount,
                C.ENCODING_PCM_16BIT
            )
        } else {
            AudioFormat.NOT_SET
        }
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val angle = ((pan + 1f) * 0.25f * Math.PI).toFloat()
        val gL = cos(angle)
        val gR = sin(angle)

        inputBuffer.order(ByteOrder.LITTLE_ENDIAN)

        // Output PCM16 (2 bytes per sample)
        val inputBytes = inputBuffer.remaining()
        val numSamples = inputBytes / 2
        val out = replaceOutputBuffer(numSamples * 2)
        out.order(ByteOrder.LITTLE_ENDIAN)

        while (inputBuffer.remaining() >= 4) {
            // Read PCM16 left & right
            val l = inputBuffer.short.toFloat() / 32768f
            val r = inputBuffer.short.toFloat() / 32768f

            // Apply panning
            val lOut = (l * gL).coerceIn(-1f, 1f)
            val rOut = (r * gR).coerceIn(-1f, 1f)

            // Convert back to PCM16
            out.putShort((lOut * 32767f).toInt().toShort())
            out.putShort((rOut * 32767f).toInt().toShort())
        }

        out.flip()
    }
}
