## TODO:
 			Get the time from gplay instead of the javascript in order to FF or RW more accurately
 			Get Errors from gplay
 			Change the audio input and stop the music player. If just mutes the player the system lags when playing
 			Complete the plugins in the cmu in order to allow more file types and fullscreen toggle

### v2.9:
      Repeat All option: Keep track of recently played videos so videos aren't repeated until the entire list is played.
      Toggling repeat 1/all or shuffle OFF resets recentlyPlayed list; shuffle ON, stopping playback, and rebooting do not.
      After last video in the list is played, jumps to the first video in the list.
      User variables are saved to localStorage: shuffle, repeat 1, repeat all, fullscreen, and recently played list.

### v2.8:
      |----------------------------------------------------------------------------------------------|
      |- Multicontroller support ----- [In Video List] ------------ [During Playback] ---------------|
      |----------------------------------------------------------------------------------------------|
      |- Press command knob ---------- [Select video] ------------- [Play/pause] --------------------|
      |- Tilt up --------------------- [Video list pgup] ---------- [Toggle fullscreen(next video)] -|
      |- Tilt down ------------------- [Video list pgdn] ---------- [Stop] --------------------------|
      |- Tilt Right ------------------ [Toggle shuffle mode] ------ [Next] --------------------------|
      |- Tilt left ------------------- [Toggle repeat all] -------- [Previous] ----------------------|
      |- Rotate command knob CCW/CW -- [Scroll video list up/dn] -- [RW/FF (10 seconds)] ------------|
      |----------------------------------------------------------------------------------------------|
      Lowered RW/FF time from 30s => 10s for beter control with command knob rotation
      Change method of managing the video list to jquery instead of bash
      Avoid problems when using files with ', " or other special characters. You must remove this character from your video name
      Use of the command knob to control the playback and to select the videos
      Use of the websocketd file provided by diginix
      Previous video option

### v2.7:
      Include pause when touching the video in the center, rewind when touching the left side and Fast Forward when touching the right side. (15% of the screen each)
      Correct problem when stopping a paused video (the icon shows an incorrect image at the beginning of the next video)

### v2.6:
      Change gst-launch for gplay, incorporing pause, resume, rw, ff
      Direct send of commands to sh (Better control)
      Close of WebSocket as it should be (saves memory)
      Change of port 55555 to 9998 in order to avoid problems with some cmu processes
      Bugfix for files with more than one consecutive white space
      Most of the times it stops the video when you put reverse with no problems

### v2.5:
      It can now logs the steps (have to enable it on the videoplayer-v2.js & videoplayer.sh files)
      closes the app if is not the current (first attempt)
      fixes the issue of pressing multiple times the search video button
      fixes the application not showing the controls again when a video play fails
      fixes playing the same video when shuffle is active
      starts using a swap file on start of the app if not running (still have to create the swap with the AIO)

### v2.4:
      Included a shuffle option
      fixed the problem of pressing the next button rapidly
      The list updates automaticaly at start

### v2.3:
      Included the status bar and adjusts to play in a window

### v2.2:
      Enabled the fullscreen Option

### v2.1:
      Included more video types

### v2.0:
      Initial Version
