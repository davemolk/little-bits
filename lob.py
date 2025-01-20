#!/usr/bin/env python3

import argparse
import requests
import webbrowser

URL_HOTTEST = "https://lobste.rs/hottest.json"
URL_NEWEST = "https://lobste.rs/newest.json"

parser = argparse.ArgumentParser() 
parser.add_argument("--hot", help="get hottest lobstas",
    action="store_true")
args = parser.parse_args()


def find_single_match(user_input, data):
    matches = [d for d in data if d["title"].lower().startswith(user_input) or d["short_id"].lower().startswith(user_input)]
    if len(matches) == 0:
        print("no matches found")
        exit(1)
    elif len(matches) == 1:
        return matches[0]
    else:
        print(f"multiple matches found: {matches}")
        exit(1)

url = URL_HOTTEST if args.hot else URL_NEWEST
resp = requests.get(url)
parsed_posts = resp.json()
for post in parsed_posts:
    print(f"title:          {post['title']}")
    print(f"url:            {post['url']}")
    print(f"tags:           {post['tags']}")
    print(f"comment count:  {post['comment_count']}")
    print(f"id:             {post['short_id']}\n")


print("type 'open <id>' to open the url in a browser, the <id> to see the post's comments, or press any key to quit.")
choice = input("(you can enter a fragment of a post's title instead of the id, or 'exit' to quit)\n").strip().lower()

if choice == "exit":
    exit(0)

if choice.startswith("open "):
    if len(choice) < 6:
        print("to open a url in a browser, format as 'open s2zxwx' or 'open <fragment of the title>'")
        exit(1)
    fragment = choice[5:]
    match = find_single_match(fragment, parsed_posts)
    webbrowser.open(match["url"])
else:
    match = find_single_match(choice, parsed_posts)
    if match['comment_count'] == 0:
        print(f"{match['title']} has no comments")
        exit(1)
    comment_url = f"https://lobste.rs/s/{match['short_id']}.json"
    resp = requests.get(comment_url)
    parsed_comments = resp.json()
    depth = {}
    for c in parsed_comments["comments"]:
        parent_id = c["parent_comment"]
        depth[c["short_id"]] = (depth.get(parent_id, -1)) + 1

    for c in parsed_comments["comments"]:
        prefix = "\t" * depth[c["short_id"]]
        print("\n{}* {}".format(prefix, c['comment_plain'].replace('\r\n\r\n', ' ')))