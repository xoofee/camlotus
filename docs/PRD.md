# 

This is an app for many interesting demo for stereo vision learning, including hartly MVG, and VSLAM/VIO/VINS

now implement this feature:

1 a home page entrypoint for a lot features

2 the first feature:
LotusCam, a camera feature that supports focus distance (focus range from near to far, like the system camera’s manual focus: adjust at what distance the image is sharp, not where in the frame to focus). Value is set with a numeric input and a slider (synchronous); 0 = near, 1 = far.
make the value persistent, and auto load and set to camera
view the camera in realtime, and a press round button to take a photo and save to system image gallery
just mimic the system camera app is ok

show the realtime K matrix on the screen and a (small and maybe transparent) switch button to turn on/off of it


# flutter_webrtc

1 use https://pub.dev/packages/flutter_webrtc to support all platform
2 existing feature should be remained
3 remove uncessary code/3rdparty package after refacor
4 support camera switch (detect multiple cameras). with a button near the right side of "taking camera" button
5 support image size set (use the highest resolution as default). show the image size at left bottom
make the settings persistent
6 do not make toast after take picture, use a quick blink to indicate taking photo, just like the behevior of common camera app made by google and apple.
7 add a gallery button near the left side of "taking camera" button. show the thumbnail of the newest photo taken by this app

the UX and behavior and layout (of 4,5,6,7) could mimic any mature camera app make by google/apple, this is not a new thing. do not reinvent, just copy them

compile in windows/android to see if any building errors, after writing the code

