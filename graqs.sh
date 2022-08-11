#!/bin/sh
# GoodReads Author Questions Scraper
# Scrapes author's Q&A section on Goodreads and merges it into one file for search/archival
# Depends: jq tidy wget
# Developed on Linux but POSIX compliant

## TODO
# write js functions to expand/hide individual spoilers so I don't have to link to GR's giant amazonbotnet scripts
# inline the CSS we actually need instead of linking to GR, or don't. who cares. low priority. works fine without a stylesheet. flag is obnoxious though
# improve expand-all function to do above to everything rather than just unhiding the one element, and make it toggle too
# parameters would be nice
# !! parse html and generate list of links to answers for easy archival
# fix page margins
# maybe try to programmatically remove some cruft like the flag, like/comment links etc
# big but would be nice: save the comments. would probably involve a major rework.
# 	would need to get a cookie and then either replace the current scrape section with scraping of every comment page 
#	-- which would multiply the requests sent at least x20 -- or possibly make it happen from the list page with some 
#	kind of cleverness. probably not worth it if it necessitated selenium or the like. though that could be fun and we need to get a cookie anyway

bold=$(tput bold)
normal=$(tput sgr0)

## config ##
author="4763.John_Scalzi"
sort="oldest" # oldest, newest, popular

filename="$author-QA-$(date +%F).html"
pre="https://www.goodreads.com/author/$author/questions?format=json&page="
post="&sort=$sort"

## scrape ##
# get first page first so we know how many pages there are
page=1
url="$pre$page$post"
wget -O $author-01.json "$url"
jq -r .content_html $author-01.json > $author-01.html
total=$(jq .total_pages $author-01.json)
for page in $(seq 2 "$total")
do
  page=$(printf "%02d" "$page") # leading zero
  url="$pre$page$post"
  stem="$author-$page"
  wget -O "$stem.json" "$url"
  page=$((page+1))
  jq -r .content_html "$stem.json" > "$stem.html"
done

## generate some html ##
author_parsed=$(echo $author | sed 's/[0-9]*\.//' | sed 's/\_/ /') # turn '0000.First_Last' into 'First Last'
myhtml_pre='<!DOCTYPE html>
<html>
<head>
<title>'
title="$author_parsed Q&amp;A ($(date +%F))"
myhtml_post='</title>
<base href="https://www.goodreads.com/">
<script>
const spoilers = document.getElementsByClassName("spoilerContainer");
function spoil() {
  for (let i = 0; i < spoilers.length; i++) {
    spoilers[i].style = "display:block";
  }
}
</script>
</head>
<body>
<button onclick="spoil()" style="border: 3px solid red">Show all spoilers</button>
<br><br>'
myhtml="$myhtml_pre$title$myhtml_post"
echo "$myhtml" > 0.html # we need it to be processed first

## merge and tidy up ##
cat ./*.html > $author-all.html
tidy -i -o "$filename" $author-all.html
echo
echo "Clean up? $bold!Deletes ALL .html and .json files in working directory!$normal"
read -r answer
answer=$(printf '%s' "$answer" | cut -c 1) # POSIX-compliant answer=${answer:0:1} (string slice)
if [ "$answer" = 'y' ]
then
  mkdir tmp &&
  cp "$filename" "tmp/$filename" &&
  rm ./*.html ./*.json &&
  mv "tmp/$filename" . &&
  rm -r tmp
fi


# Copyleft: all wrongs reversed
