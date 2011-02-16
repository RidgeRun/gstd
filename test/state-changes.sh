#! gst-client --session

strict on

list-pipe

sh "echo Test synch state changes."
create "videotestsrc ! ffmpegcolorspace ! videoscale ! xvimagesink"
ready
sh "sleep 1"
pause
sh "sleep 1"
play
sh "sleep 1"
pause
sh "sleep 1"
ready
sh "sleep 1"
null
destroy


sh "echo Test asynch state changes."
create "videotestsrc ! ffmpegcolorspace ! videoscale ! xvimagesink"
aready
sh "sleep 1"
apause
sh "sleep 1"
aplay
sh "sleep 1"
apause
sh "sleep 1"
aready
sh "sleep 1"
anull
destroy

