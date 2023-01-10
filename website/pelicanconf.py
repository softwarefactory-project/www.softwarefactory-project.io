# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Red Hat'
CC_LICENSE = True
SITENAME = u'Software Factory'
SITEURL = 'https://www.softwarefactory-project.io'

PATH = 'content'
THEME = 'themes/pelican-bootstrap3'
SITELOGO = 'images/SoftwareFactory-logo.svg'
SITELOGO_SIZE = '20px'
BOOTSTRAP_NAVBAR_INVERSE = 'True'
# BANNER = '/images/banner.svg'
# BANNER_ALL_PAGES = 'True'

PAGE_TRANSLATION_ID = None
ARTICLE_TRANSLATION_ID = None

TIMEZONE = 'UTC'

DEFAULT_LANG = u'en'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
FEED_ATOM = 'atom.xml'
CATEGORY_FEED_ATOM = '{slug}.xml'
FEED_RSS = 'rss.xml'
CATEGORY_FEED_RSS = '{slug}.rss'
TRANSLATION_FEED_ATOM = None

LOAD_CONTENT_CACHE = False
PLUGIN_PATHS = ['plugins/']
PLUGINS = []

ARTICLE_EXCLUDES = ['docs']
PAGE_EXCLUDES = ['docs']
STATIC_PATHS = ['images', 'docs', 'demo-codes']

# HIDE_SIDEBAR = True
# DISPLAY_CATEGORIES_ON_SIDEBAR = True
DISPLAY_RECENT_POSTS_ON_SIDEBAR = True

# Blogroll
# LINKS = (('sf-project.io ', 'https://softwarefactory-project.io'),
#         ('review.rdoproject.org', 'https://review.rdoproject.org'),)

# Social widget
# SOCIAL = (('You can add links in your config file', '#'),
#           ('Another social link', '#'),)

DEFAULT_PAGINATION = 10

DISPLAY_BREADCRUMBS = False
DISPLAY_CATEGORY_IN_BREADCRUMBS = False

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True

PYGMENTS_STYLE= "solarizedlight"
DOCUTIL_CSS = True

SHOW_ARTICLE_AUTHOR = True
