package org.webrtc.audio;

public class AudioProcessingState {
    public AudioProcessingComponentState getEchoCancellation() { return new AudioProcessingComponentState(); }
    public AudioProcessingComponentState getNoiseSuppression() { return new AudioProcessingComponentState(); }
    public AudioProcessingComponentState getAutoGainControl() { return new AudioProcessingComponentState(); }
    public AudioProcessingComponentState getHighPassFilter() { return new AudioProcessingComponentState(); }
    public AudioProcessingMode getMode() { return AudioProcessingMode.AUTOMATIC; }
    public AudioProcessingImplementation getImplementation() { return AudioProcessingImplementation.UNKNOWN; }
}
