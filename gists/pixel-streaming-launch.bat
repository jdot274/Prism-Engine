@echo off
REM Launch UE 5.7 build in Pixel Streaming mode.
REM Run from the directory containing your packaged build (or the editor's Binaries\Win64).

setlocal

set PROJECT_EXE=MyGame.exe
set SIGNALLING_URL=ws://localhost:8888
set RES_X=1920
set RES_Y=1080

REM Encoder + bandwidth
set ENCODER_BITRATE_TARGET=5000000
set ENCODER_BITRATE_MAX=8000000
set ENCODER_MIN_QP=20
set ENCODER_MAX_QP=40

REM Build the command line
"%PROJECT_EXE%" ^
    -PixelStreamingURL=%SIGNALLING_URL% ^
    -RenderOffScreen ^
    -AudioMixer ^
    -ForceRes ^
    -ResX=%RES_X% ^
    -ResY=%RES_Y% ^
    -PixelStreamingEncoderTargetBitrate=%ENCODER_BITRATE_TARGET% ^
    -PixelStreamingWebRTCMaxBitrate=%ENCODER_BITRATE_MAX% ^
    -PixelStreamingEncoderMinQP=%ENCODER_MIN_QP% ^
    -PixelStreamingEncoderMaxQP=%ENCODER_MAX_QP% ^
    -unattended ^
    -log

endlocal
