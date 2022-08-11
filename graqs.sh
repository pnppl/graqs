#!/bin/sh
# Goodreads Author Questions Scraper
# Scrapes author's Q&A section on Goodreads and merges it into one file for search/archival
# Depends: jq tidy wget
# Developed on Linux but POSIX compliant

## TODO
# parameters would be nice
# !! parse html and generate list of links to answers for easy archival
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
  page_0=$(printf "%02d" "$page") # leading zero
  url="$pre$page$post"
  stem="$author-$page_0"
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
<style>
img {
	height: 50px;
	width: 50px;
	border-radius: 25px;
	float: left;
	margin-right: 10px;
}

body {
	margin-left: 10px;
	margin-right: 10px;
	font-family: serif;
	font-size: 14px;
	line-height: 18px;
}


ul {
	list-style: none;
	margin-left: 20px;
}

li {
	display: inline;
}

li .like_it, .flagAnswer {
	display: none;
}

a {
	text-decoration: none;
	color: #181818;
}

a:hover {
	text-decoration: underline;
}

.communityAnswererName a {
	font-weight: bold;
	color: #00635d;
}

.communityAnswerText {
	font-family: sans-serif;
}

.allCommunityAnswers a{
	font-family: sans-serif;
	color: #00635d;
}

.likesCount {
	color: #999999;
}

.footerItem {
	text-transform: capitalize;
	font-size: 11px;
}

.communityAnswerTextContainer {
	margin-left: 60px;
}

.questionText {
	margin-bottom: 13px;
}

.communityQuestionAndAnswer {
	border-bottom: 1px solid #DFDFDF;
	margin-bottom: 15px;
}
</style>
</head>
<body>
<form>
	<input type="button" value="Show all spoilers" id="spoil_button" onclick="spoilAll()" style="border: 3px solid red">
</form>
<br>'
myhtml="$myhtml_pre$title$myhtml_post"
myscript='<script>
const spoilers = document.getElementsByClassName("spoilerContainer");
const spoiler_show = document.getElementsByClassName("jsShowSpoiler spoilerAction");
const spoiler_hide = document.getElementsByClassName("jsHideSpoiler spoilerAction");
var spoiled = false;

for (var i = 0; i < spoilers.length; i++) {
	spoiler_show[i].addEventListener("click", showSpoiler);
	spoiler_show[i].setAttribute("id", i);
	spoiler_hide[i].addEventListener("click", hideSpoiler)
	spoiler_hide[i].setAttribute("id", i);
}

function showSpoiler() {
	spoilers[this.id].style = "display:block";
	spoiler_show[this.id].style = "display:none";
	spoiler_hide[this.id].style = "display:inline";
}

function hideSpoiler() {
	spoilers[this.id].style = "display:none";
	spoiler_show[this.id].style = "display:inline";
	spoiler_hide[this.id].style = "display:none";
}

function spoilAll() {
	if (spoiled === false) {
		for (let i = 0; i < spoilers.length; i++) {
			spoilers[i].style = "display:block";
			spoiler_show[i].style = "display:none";
			spoiler_hide[i].style = "display:inline";
		}
		document.querySelector("#spoil_button").value = "Hide all spoilers";
		document.querySelector("#spoil_button").style = "border: 3px solid green";
		spoiled = true;
	}
	else {
		for (let i = 0; i < spoilers.length; i++) {
			spoilers[i].style = "display:none";
			spoiler_show[i].style = "display:inline";
			spoiler_hide[i].style = "display:none";
		}
		document.querySelector("#spoil_button").value = "Show all spoilers";
		document.querySelector("#spoil_button").style = "border: 3px solid red";
		spoiled = false;
	}
}
</script>'
echo "$myhtml" > 0.html # we need this to be processed first
echo "$myscript" > z.html # oops, we need the script processed last

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
