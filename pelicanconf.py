AUTHOR = 'haoadoresorange'
SITENAME = "Inside a comtam enthusiast's brain"
SITEURL = ''

TIMEZONE = 'America/Montreal'

DEFAULT_LANG = 'en'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# # Blogroll
# LINKS = (('Pelican', 'https://getpelican.com/'),
#          ('Python.org', 'https://www.python.org/'),
#          ('Jinja2', 'https://palletsprojects.com/p/jinja/'),
#          ('You can modify those links in your config file', '#'),)

# # Social widget
# SOCIAL = (('You can add links in your config file', '#'),
#           ('Another social link', '#'),)

# Links and social cruft
# NOTE: These aren't called just LINKS and SOCIAL because those are assumed by
# the default theme to be 2-tuples, but I need more info.
LINKS_EX = ((
    'everything',
    '/everything/',
    '#c57be6', 'category-everything.png',
    "why chose when you can have it all",
), (   
    'blog',
    '/blog/',
    '#f6b441', 'category-blog.png',
    "detailed, thoughtful prose about softwares and various subjects",
), (
    'dlog',
    '/dlog/',
    '#ee7300', 'category-dlog.png',
    "quick updates on what i'm doing lately",
), (
#     'release',
#     '/release/',
#     '#4a83c5', 'category-release.png',
#     "things i've released into the wild, and maybe my thoughts on them",
# ), (
#    'art',
#    '/art/',
#    '#41c518', 'category-art.png',
#    "i'm learning to draw, here are the results",
#), (
#    'cats',
#    'http://lexyeevee.tumblr.com/tagged/sphynx',
#    '#deb46a', 'category-cat-photos.png',
#    "our house is overrun with them and they are the best",
#), (
    'archives',
    '/everything/archives/',
    '#399ccd', 'category-archives.png',
    "travel back in time",
))

SOCIAL_EX = ((
    'github',
    'https://github.com/haoadoresorange',
    '#4183c4', 'logo-github.png',
    "hacking the gibson",
), ( 
    'email',
    'mailto:haoadores@comtam.dev',
    '#9966cc', 'logo-email.png',
    "email is here to stay",
), (
    'twitter',
    'https://twitter.com/haoadoresorange',
    '#55acee', 'logo-twitter.png',
    "a not so dumb social network",
), (
#     'mastodon',
#     'https://mastodon.social/@eevee',
#     '#3088d4', 'logo-mastodon.png',
#     "trickle of bad jokes",
# ), (
#     'art tumblr',
#     'https://lexyeevee.tumblr.com/',
#     '#35465c', 'logo-tumblr.png',
#     "just art",
# ), (
#     'itch.io',
#     'https://eevee.itch.io/',
#     '#fa5c5c', 'logo-itch.png',
#     "indie games",
# ), (
    'twitch',
    'https://twitch.tv/lucd',
    '#6441a4', 'logo-twitch.png',
    "occasional game streams",
), (
    'youtube',
    'https://www.youtube.com/channel/UCErd6zzmLJ-U1ReFrle3kBQ',
    '#cc181e', 'logo-youtube.png',
    "not sure what to upload there yet",
), (
    'buy me a coffee',
    'https://www.buymeacoffee.com/haoadoresorange',
    '#FF813F', 'logo-buymeacoffee.png',
    "help feed me",
), (
#     'square',
#     'https://cash.me/$eevee',
#     '#29c501', 'logo-square-cash.png',
#     "just give me money?",
# ), (
    'paypal',
    'https://www.paypal.me/haoadoresorange',
    '#009cde', 'logo-paypal.png',
    "wanna give me money more money ?",
))

DEFAULT_PAGINATION = 10
DEFAULT_ORPHANS = 3
PAGINATION_PATTERNS = (
    (1, '{base_name}/', '{base_name}/index.html'),
    (2, '{base_name}/page/{number}/', '{base_name}/page/{number}/index.html'),
)

THEME = 'theme'

def sort_by_article_count(tags):
    return sorted(tags, key=lambda pairs: len(pairs[1]), reverse=True)

JINJA_FILTERS = dict(
    sort_by_article_count=sort_by_article_count,
)

PATH = 'content/'
STATIC_PATHS = ['favicon.png']

# Leave .html alone; I only use it for static attachments, not posts
READERS = dict(html=None)

# For the landing page
TEMPLATE_PAGES = {
    '../theme/templates/home.html': 'index.html',
}

ARTICLE_URL = '{category}/{date:%Y}/{date:%m}/{date:%d}/{slug}/'
ARTICLE_SAVE_AS = '{category}/{date:%Y}/{date:%m}/{date:%d}/{slug}/index.html'
AUTHOR_SAVE_AS = False
AUTHORS_SAVE_AS = False
CATEGORY_URL = '{slug}/'
CATEGORY_SAVE_AS = '{slug}/index.html'
INDEX_SAVE_AS = 'everything/index.html'
TAG_URL = 'tags/{slug}/'
TAG_SAVE_AS = 'tags/{slug}/index.html'
TAGS_URL = 'tags/'
TAGS_SAVE_AS = 'tags/index.html'

FILENAME_METADATA = '(?P<date>\d{4}-\d{2}-\d{2})-(?P<slug>.*)'

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True

# Plugins
PLUGIN_PATHS = ["pelican-plugins"]
PLUGINS = [
    'summary',
]

# Plugin config for summary
SUMMARY_END_MARKER = '<!-- summary -->'
# This is actually a stock setting; I don't want an automatic summary if I
# don't use an explicit marker
SUMMARY_MAX_LENGTH = None
