#!/bin/sh

# Downloads video from a reddit post.
# Method from u/budzen. https://www.reddit.com/r/Enhancement/comments/6yl9tt/any_way_to_get_the_direct_link_to_reddithosted/duwxtij/

#Help.
function show_help () {
	echo "Usage: rvd <option> <url>
	-h		Show this help page.
	-o FILE		Write output to FILE.
	-f FORMAT	Write to FORMAT (mp4, m4a etc.) No webm."
	}

# Options fluff.
output_file=""
output_format="mp4"

while getopts "ho:f:" o; do
	case "${o}" in
	h)	show_help & exit 0
		;;
	o)	output_file="$OPTARG"
		;;
	f)	output_format="$OPTARG"
		;;
	\?*)	show_help & exit 0
		;;
	esac
done
shift $((OPTIND -1))

if [ $# -eq 0 ]; then
	show_help & exit 0
fi

# Get json from link and extract the video and audio urls.
media_json="${1}.json"

echo "$media_link"

video_url=$(curl -s -A "random" "$media_json" | json_pp |
		grep -m 1 fallback_url | sed 's/.*: "//;s/",//')

audio_url=$(echo "$video_url" | sed 's/DASH.*?/audio?/')

filename=$(curl -s -A "random" "$media_json" | json_pp |
		grep -m 2 title | sed 's/.*: "//;s/",//;s/ /-/g;s/\.//g' |
		tail -n1)
echo "title: $filename"

#Pull audio and video from the urls.
echo "Pulling audio from $audio_url:"
	wget -O rvd-audio "$audio_url"
echo "Pulling video from $video_url:"
	wget -O rvd-video "$video_url"

# Define filename if not overwritten by option.
if [ -z "$output_file" ]; then
	echo "Output file is empty, naming $filename..."
	output_file="$filename"
fi

# Combine the two with ffmpeg.
ffmpeg -i rvd-video -i rvd-audio -c:v copy -c:a copy "$output_file"."$output_format"

# Cleanup.
rm rvd-video rvd-audio
exit 0
