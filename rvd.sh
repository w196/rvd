#!/bin/bash

# Downloads video from a reddit post.
# Method from u/budzen. https://www.reddit.com/r/Enhancement/comments/6yl9tt/any_way_to_get_the_direct_link_to_reddithosted/duwxtij/

function fetch_json 
{ # Get json from link and extract the video and audio urls.
	page_json=$(curl -s -A "random" "${1}.json")

	# this is the SHORT way of doing it.
	video_url=$(jq -r '.[].data.children[].data.secure_media.reddit_video.fallback_url' <<< $page_json | head -n 1)
	audio_url=$(sed 's/DASH.*?/audio?/' <<< $video_url | head -n 1)
}

function get_title
{ 
	post_title=$(jq -r '.[].data.children[].data.title' <<< $page_json | head -n 1 |
		tr -d '[:punct:]' | sed 's/\ /_/g' | cut -d "_" -f 1-4 )
} 

function pull_content 
{	#Pull audio and video from the urls.
	echo "Pulling video from $video_url:"
		wget -O rvd-video "$video_url"
	echo "Pulling audio from $audio_url:"
		wget -O rvd-audio "$audio_url"

	# Combine the two with ffmpeg. Re-encode if webm requested.
	if [ "$output_format" == "webm" ]; then
		ffmpeg -i rvd-video -i rvd-audio -c:v libvpx -c:a libvorbis "$post_title".webm
	else
		ffmpeg -i rvd-video -i rvd-audio -c:a copy -c:v copy "$post_title"."$output_format"
	fi
}

# Options fluff.
output_format="mp4"

while getopts "ho:f:b:" o; do
	case "${o}" in
	f)	output_format="$OPTARG"
		;;
	esac
done
shift $((OPTIND -1))

if [ $# -eq 0 ]; then
	echo "Usage:
	./rvd.sh <url>..."
fi

for arg; do
	fetch_json $arg && get_title && pull_content
done

# Cleanup.
rm -f rvd-video rvd-audio
exit 0
