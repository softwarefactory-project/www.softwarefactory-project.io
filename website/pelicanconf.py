# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Software Factory'
SITENAME = u'Software Factory'
SITEURL = ''

PATH = 'content'
THEME = 'themes/pelican-bootstrap3'

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

# Blogroll
LINKS = (('sf-project.io ', 'https://softwarefactory-project.io'),
         ('review.rdoproject.org', 'https://review.rdoproject.org'),)

# Social widget
#SOCIAL = (('You can add links in your config file', '#'),
#          ('Another social link', '#'),)

DEFAULT_PAGINATION = 10

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True
