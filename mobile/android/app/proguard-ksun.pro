# KSUN API 22: disable R8 optimization to preserve all API version checks.
# R8's API modeling outlines higher-API calls into synthetic classes
# but removes version guards, causing NoSuchMethodError on API 22.
-dontoptimize

# webrtc-sdk 137 lacks these classes from 144; they're for optional features
# (E2EE frame cryptor, advanced audio processing) not used in our PTT app.
-dontwarn org.webrtc.FrameCryptorKeyDerivationAlgorithm
-dontwarn org.webrtc.audio.AudioProcessingComponentOptions
-dontwarn org.webrtc.audio.AudioProcessingComponentState
-dontwarn org.webrtc.audio.AudioProcessingImplementation
-dontwarn org.webrtc.audio.AudioProcessingMode
-dontwarn org.webrtc.audio.AudioProcessingOptions
-dontwarn org.webrtc.audio.AudioProcessingOptionsResult$Code
-dontwarn org.webrtc.audio.AudioProcessingOptionsResult
-dontwarn org.webrtc.audio.AudioProcessingState
