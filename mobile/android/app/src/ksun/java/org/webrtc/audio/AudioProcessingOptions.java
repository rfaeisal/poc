package org.webrtc.audio;

public class AudioProcessingOptions {
    public final AudioProcessingComponentOptions echoCancellation;
    public final AudioProcessingComponentOptions noiseSuppression;
    public final AudioProcessingComponentOptions autoGainControl;
    public final AudioProcessingComponentOptions highPassFilter;

    public AudioProcessingOptions(
            AudioProcessingComponentOptions echoCancellation,
            AudioProcessingComponentOptions noiseSuppression,
            AudioProcessingComponentOptions autoGainControl,
            AudioProcessingComponentOptions highPassFilter) {
        this.echoCancellation = echoCancellation;
        this.noiseSuppression = noiseSuppression;
        this.autoGainControl = autoGainControl;
        this.highPassFilter = highPassFilter;
    }
}
