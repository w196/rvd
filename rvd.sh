#!/bin/bash

# Downloads video from a reddit post.
# Method from u/budzen. https://www.reddit.com/r/Enhancement/comments/6yl9tt/any_way_to_get_the_direct_link_to_reddithosted/duwxtij/

#Help.
function show_help () {
	echo "Usage: rvd <option> <url>
	-h		Show this help page.
	-o FILE		Write output to FILE.
	"
	}

#Options fluff.
output_file="rvd-output"
output_format="mp4"

while getopts "ho:" o; do
	case "${o}" in
	h)	show_help & exit 0
		;;
	o)	output_file=$OPTARG
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
media_link=$1
media_json=`echo $media_link | sed "s/\/$/.json/"`

echo $media_link

video_url=`curl -s -A "random" $media_json | json_pp |
		grep -m 1 fallback_url | sed 's/.*: "//;s/",//'`

audio_url=`echo $video_url | sed 's/DASH.*?/audio?/'`

#Pull audio and video from the urls.
echo "Pulling audio from $audio_url:"
	wget -O rvd-audio $audio_url
echo "Pulling video from $video_url:"
	wget -O rvd-video $video_url

#Combine the two with ffmpeg.
ffmpeg -i rvd-video -i rvd-audio -c:v copy -c:a aac $output_file.$output_format

#Cleanup.
rm rvd-video rvd-audio
exit 0
