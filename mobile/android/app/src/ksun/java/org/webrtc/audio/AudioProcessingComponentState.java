package org.webrtc.audio;

public class AudioProcessingComponentState {
    private final AudioProcessingComponentOptions requested;

    public AudioProcessingComponentState() {
        this.requested = null;
    }

    public AudioProcessingComponentOptions getRequested() { return requested; }
    public boolean isSoftwareResolved() { return false; }
    public boolean isSoftwareActive() { return false; }
    public boolean isPlatformAvailable() { return false; }
    public boolean isPlatformResolved() { return false; }
    public boolean isPlatformActive() { return false; }
    public AudioProcessingImplementation getEffective() { return AudioProcessingImplementation.UNKNOWN; }
}
