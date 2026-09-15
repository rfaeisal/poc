package org.webrtc.audio;

public class AudioProcessingOptionsResult {
    public enum Code {
        APPLIED,
        STORED,
        REJECTED_REMOTE_TRACK,
        REJECTED_INVALID_COMBINATION,
        REJECTED_PLATFORM_UNAVAILABLE,
        APPLY_FAILED
    }

    private final boolean success;
    private final Code code;
    private final String message;

    public AudioProcessingOptionsResult(boolean success, Code code, String message) {
        this.success = success;
        this.code = code;
        this.message = message;
    }

    public boolean isSuccess() { return success; }
    public Code getCode() { return code; }
    public String getMessage() { return message; }
}
