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


