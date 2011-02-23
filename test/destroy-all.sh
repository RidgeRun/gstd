#! ../src/gst-client-interpreter --session

strict on

sh "echo Test destroy all."
sh "echo -------------------------"
list-pipes
sh "echo Destroy all pipes"
destroy-all
sh "echo Create first pipe"
create "videotestsrc name=src ! ffmpegcolorspace ! videoscale ! xvimagesink name=sink"
sh "echo Create second pipe"
create "videotestsrc name=src ! ffmpegcolorspace ! videoscale ! xvimagesink name=sink"
sh "echo Create third pipe"
create "videotestsrc name=src ! ffmpegcolorspace ! videoscale ! xvimagesink name=sink"
sh "echo Create fourth pipe"
create "videotestsrc name=src ! ffmpegcolorspace ! videoscale ! xvimagesink name=sink"
list-pipes
sh "echo Destroy all pipes"
destroy-all
list-pipes



