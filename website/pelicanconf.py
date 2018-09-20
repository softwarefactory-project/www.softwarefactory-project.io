# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Red Hat'
SITENAME = u'Software Factory'
SITEURL = ''

PATH = 'content'
THEME = 'themes/pelican-bootstrap3'
SITELOGO = 'images/SoftwareFactory-logo.svg'
SITELOGO_SIZE = '20px'
BOOTSTRAP_NAVBAR_INVERSE = 'True'
# BANNER = '/images/banner.svg'
# BANNER_ALL_PAGES = 'True'

TIMEZONE = 'UTC'

DEFAULT_LANG = u'en'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

LOAD_CONTENT_CACHE = False
PLUGIN_PATHS = ['plugins/']
PLUGINS = []

ARTICLE_EXCLUDES = ['docs']
PAGE_EXCLUDES = ['docs']
STATIC_PATHS = ['images', 'docs']

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
