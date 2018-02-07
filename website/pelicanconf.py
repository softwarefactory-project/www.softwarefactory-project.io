# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Software Factory'
SITENAME = u'Software Factory'
SITEURL = ''

PATH = 'content'
THEME = 'themes/pelican-bootstrap3'
SITELOGO = 'images/SoftwareFactory.svg'
SITELOGO_SIZE = '20px'
BOOTSTRAP_NAVBAR_INVERSE = 'True'
# BANNER = '/images/banner.svg'
# BANNER_ALL_PAGES = 'True'

TIMEZONE = 'Europe/Paris'

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

DISPLAY_BREADCRUMBS = True
DISPLAY_CATEGORY_IN_BREADCRUMBS = True

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True
