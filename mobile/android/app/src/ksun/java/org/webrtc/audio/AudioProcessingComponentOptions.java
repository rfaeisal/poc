package org.webrtc.audio;

public class AudioProcessingComponentOptions {
    private final boolean enabled;
    private final AudioProcessingMode mode;

    public AudioProcessingComponentOptions(boolean enabled, AudioProcessingMode mode) {
        this.enabled = enabled;
        this.mode = mode;
    }

    public boolean isEnabled() { return enabled; }
    public AudioProcessingMode getMode() { return mode; }
}
