# For testing publish with local nginx.

import os
import sys
sys.path.append(os.curdir)
from pelicanconf import *

# If your site is available via HTTPS, make sure SITEURL begins with https://
SITEURL = 'http://0.0.0.0:8000'
# RELATIVE_URLS = True

FEED_DOMAIN = SITEURL
FEED_MAX_ITEMS = 17
FEED_ATOM = 'feeds/atom.xml'
FEED_ALL_ATOM = 'feeds/all.atom.xml'
CATEGORY_FEED_ATOM = 'feeds/{slug}.atom.xml'
FEED_RSS = 'feeds/rss.xml'
FEED_ALL_RSS = 'feeds/all.rss.xml'
CATEGORY_FEED_RSS = 'feeds/{slug}.rss.xml'

DELETE_OUTPUT_DIRECTORY = True
OUTPUT_PATH = 'output-publish/'

# Following items are often useful when publishing

DISQUS_SITENAME = 'haoadorescomtam'
# GOOGLE_ANALYTICS = 'UA-25539054-1'
