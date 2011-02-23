#! ../src/gst-client-interpreter --session

strict on

sh "echo Test synch state changes."
sh "echo -------------------------"
create "videotestsrc name=src ! ffmpegcolorspace ! videoscale ! xvimagesink name=sink"
ready
get-elem-state src
get-elem-state sink
ping-pipe
sh "sleep 1"
get-state
sh "echo pause"
pause
get-elem-state src
get-elem-state sink
ping-pipe
sh "sleep 1"
get-state
play
sh "echo play"
get-elem-state src
get-elem-state sink
ping-pipe
sh "sleep 1"
get-state
sh "echo pause"
pause
get-elem-state src
get-elem-state sink
ping-pipe
sh "sleep 1"
get-state
sh "echo ready"
ready
get-elem-state src
get-elem-state sink
ping-pipe
sh "sleep 1"
get-state
sh "echo null."
null
get-state
destroy

sh "echo Test asynch state changes."
sh "echo -------------------------"
create "videotestsrc name=src ! ffmpegcolorspace ! videoscale ! xvimagesink name=sink"
sh "echo aready."
aready
get-elem-state src
get-elem-state sink
sh "sleep 1"
get-state
sh "echo apause."
apause
get-elem-state src
get-elem-state sink
sh "sleep 1"
get-state
sh "echo aplay."
aplay
get-elem-state src
get-elem-state sink
sh "sleep 1"
get-state
sh "echo apause."
apause
get-elem-state src
get-elem-state sink
sh "sleep 1"
get-state
sh "echo aready."
aready
get-elem-state src
get-elem-state sink
sh "sleep 1"
get-state
sh "echo anull."
anull
destroy

