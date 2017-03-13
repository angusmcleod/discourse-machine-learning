#!/usr/bin/env python

import requests
import json

f = open('stack-law-titles', 'r+')

url = "https://api.stackexchange.com/2.2/questions?order=desc&sort=activity&site=law.stackexchange.com&pagesize=100"
headers = { "Accept-Encoding": "gzip" }

r = requests.get(url, headers=headers)
parsed = json.loads(r.text)

for post in parsed['items']:
    print post['title']
    print >>f, post['title']
