#!/bin/sh

# Downloads video from a reddit post.
# Method from u/budzen. https://www.reddit.com/r/Enhancement/comments/6yl9tt/any_way_to_get_the_direct_link_to_reddithosted/duwxtij/

#Help.
function show_help () {
	echo "Usage: rvd <option> <url>
	-h 		Show this help page.
	-f FORMAT	Write to FORMAT (mp4, m4a etc.)
	-b BITRATE	Write with BITRATE if webm."
}

function fetch_json () { # Get json from link and extract the video and audio urls.
	output_file="" 

	media_json="${1}.json"

	echo "$media_link"

	video_url=$(curl -s -A "random" "$media_json" | json_pp |
			grep -m 1 fallback_url | sed 's/.*: "//;s/",//')

	audio_url=$(echo "$video_url" | sed 's/DASH.*?/audio?/')

	filename=$(curl -s -A "random" "$media_json" | json_pp |
			grep -m 2 title | sed 's/.*: "//; s/",//; s/ /-/g; s/\.//g; s/\\//g; s/"//g;' |
			tail -n1)
	echo "title: $filename"

	# Define filename if not overwritten by option.
	output_file=$(echo "$filename" | cut -d "-" -f 1-5)
}

function pull_content {	#Pull audio and video from the urls.
	echo "Pulling audio from $audio_url:"
		wget -O rvd-audio "$audio_url"
	echo "Pulling video from $video_url:"
		wget -O rvd-video "$video_url"
	
	# Combine the two with ffmpeg. Re-encode if webm requested.
	if [ "$output_format" == "webm" ]; then
		ffmpeg -i rvd-video -i rvd-audio -b:v "$output_bitrate" -c:v libvpx -c:a libvorbis "$output_file".webm
	else
		ffmpeg -i rvd-video -i rvd-audio -c:a copy -c:v copy "$output_file"."$output_format"
	fi
}

function do_bulk {
	for input in $#; do 
		fetch_json
		pull_content
	done
}

# Options fluff.
output_file=""
output_format="mp4"

while getopts "ho:f:b:" o; do
	case "${o}" in
	h)	show_help && exit 0
		;;
	f)	output_format="$OPTARG"
		;;
	b)	output_bitrate="$OPTARG"
		;;
	\?*)show_help && exit 0
		;;
	esac
done
shift $((OPTIND -1))

if [ $# -eq 0 ]; then
	show_help & exit 0
fi

for arg; do
	fetch_json $arg && pull_content
done

# Cleanup.
rm rvd-video rvd-audio
exit 0
