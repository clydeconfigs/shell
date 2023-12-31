#!/bin/sh

cq=19

if [ "$#" -eq 0 ]; then
    echo "No CQ provided. Setting to $cq"
else
    echo "CQ: $@"
    cq=$@
fi

if [ -d "$HOME/Recordings" ]; then
    echo "The folder exists."
else
    mkdir "$HOME/Recordings"
fi

# Function to combine audio and video into a single file
combine_audio_video() {
    audio_file="$1"
    video_file="$2"
    output_file="$HOME/Recordings/recording-$(date -R).mkv"

    ffmpeg -i "$video_file" -i "$audio_file" -c:v libx264 -crf 23 -preset medium -c:a aac -strict experimental -b:a 192k "$output_file" && rm -f "$audio_file" "$video_file"
}

# Function to start recording audio and video
record_audio_video() {
    video_file="$HOME/Recordings/video-$(date -R).mkv"
    audio_file="$HOME/Recordings/audio-$(date -R).flac"

	# Start video recording
	ffmpeg -y \
	    -f x11grab \
	    -framerate 30 \
	    -s "$(xrandr | grep -oP '(?<=current ).*(?=,)' | tr -d ' ')" \
	    -i "$DISPLAY" \
	    -r 24 \
	    -use_wallclock_as_timestamps 1 \
	    -f alsa -thread_queue_size 1024 -i default \
	    -c:v h264_nvenc -cq:v $cq -b:v 2M -preset p7 -r 30 \
	    -c:a flac \
	    -s 1280x720 \
	    "$video_file" &


    echo $! > /tmp/recordingpid
    echo "Recording started..."

    # Start audio recording in the background
    ffmpeg -f alsa -i default -c:a flac "$audio_file" &
    audio_pid=$!

    # Wait for the user to stop the script
    read -p "Press Enter to stop recording..."

    # Stop video recording
    kill "$(cat /tmp/recordingpid)"

    # Stop audio recording
    kill $audio_pid

    combine_audio_video "$audio_file" "$video_file"
    echo "Recording stopped."
}

# Start recording audio and video
record_audio_video
