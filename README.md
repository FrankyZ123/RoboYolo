# RoboYolo

## Summary
Hello and welcome! This is the code repository for my Computer Science Degree Capstone Project at Minerva. The goal of the project is simple: expand the Mindstorm development ecosystem by demonstrating and implementating novel machine learning concepts such that a non-technical user can build and "program" task specific LEGO robots. It currently provides tooling for a user to "program" YOLOv3 given a constrained set of hyperparameters such that, when connected to a two wheel powered robot, said robot will horizontally track and center on a user input object at a certain threshold. Take a look around and let me know if you have any questions!

## Up and Running
To get this project up and running, you'll need to have [XCode](https://developer.apple.com/xcode/) installed. Simply curl this project into a local directory, open this project in XCode, connect your iOS device to your computer, and build the application on your iOS device! I was only able to test this implementation on an iPhone 8; it's possible both the simplified programming interface and the real-time computer vision relay do not show up properly on a different make / model.

To get the robot implementation working, you'll also need to have a LEGO EV3 Mindstorm kit around, turn it on, connect your iOS device to the Mindstorm via Bluetooth (you should be able to do this easily in settings), and you're off to the races!

If you have any questions or concerns, feel free to open a PR or an Issue on this repo and I'll address as soon as I can.

## Works Consulted / Shout Outs
EV3/ folder is from: https://github.com/andiikaa/ev3ios \
RobotConnection.swift is from: https://github.com/chihayafuru/SampleOfEV3IOS \
ViewController.swift adapted from: https://www.youtube.com/watch?v=SkgHz8nw5V8&t=895s
