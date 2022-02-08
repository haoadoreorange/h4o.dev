title: Build & host my blog with Pelican (part 0)  
tags: build, blog, pelican, python

I've been writing since couple years back, sort of a diary activity or sometimes
just to take note what I learned. I posted some of it on Medium. The thing is,
not only that I write, I make stuffs too, and Medium is not for anything else
but writing. It's like a newspaper, meaning no landing page for me to show my
stuffs 😢

Then there's Wordpress, but I didn't need the dynamic nature, nor any database,
it just seemed way overkill to host one. To be fair, Wordpress is a full-feature
CMS, which I guess if I'm gonna make a blog for my mom, maybe I'll use it.

<!-- summary -->

# Why Pelican ?

I think what really tipped me off the edge is, although they provide you an
all-in-one solution to write, their editors suck 👎 If I'm gonna host the blog
myself, I must be able to write on whatever I want. I write notes in Markdown,
so wanting to convert Markdown to HTML came quite naturally. I've been following
[Eevee's blog](https://eev.ee/) (she makes amazing stuffs, give it a look, as of
the moment of this writing I took a lot of assets from her blog) and really
enjoyed the layout. So I figured, I'd see how she'd built it. That's when I came
across [static site generator (SSG)](https://jamstack.org/generators/). Eevee
uses [Pelican](https://blog.getpelican.com/), and because the name seems cool,
plus its configuration and plugins are in Python (which I hate but quite
comfortable with, meaning I'd be able to hack around if needed), so I decided
I'd use it too. Indeed it's my first time with a SSG.

# A very first look

_The doc for installation and quick-start guide is quite short and very well
written, if you know nothing about Pelican, make sure you finish it before
reading any further (Super highly recommend that you install Pelican with
virtualenv)._

I followed the installation doc and quick-start guide to get a first look inside
a Pelican project. It was pretty easy using `pelican-quickstart` cli and leaving
most of the options as default. Before looking into any configurations, I
decided it's important to well understand the concepts and folder structure. On
retrospect, it surely helped me debugging configurations whenever things go
south. Let's take a look.

```
.
├── content
│   └── post1.md
├── Makefile
├── output
│   ├── archives.html
│   ├── author
│   │   └── sic.html
│   ├── authors.html
│   ├── categories.html
│   ├── category
│   │   └── misc.html
│   ├── index.html
│   ├── post1.html
│   ├── tags.html
│   └── theme
├── pelicanconf.py
├── publishconf.py
└── tasks.py
```

This is what a SSG does, it takes what inside _content_ and generate an _output_
directory containing `.html` files for displaying the content in the browser,
all the other files are for configurations and automation. The _content_
directory is where I put my blog articles, each of which there's several
metadata I need to specify, such as title, date, category...etc. I think Pelican
support several text file extensions, but I only use Markdown anyway.

Look into the `output` folder, it's clear that `post1.md` got converted into
`post1.html`, `index.html` is obviously the landing page. How about the rest ?
Those are the page that sort the metadata that we explicitly defined, e.g
`author.html` gives us the list of article by that author and `authors.html`
links to each `author.html` page. By default, I don't think the basic landing
page show us any link to these metadata pages, but if you're running the dev
server, you can access by typing the url, e.g `/authors`, and so on.

We refered to articles, and then _pages_ which is a concept of Pelican, that is
for example the _contact-me_ or _about-me_ page, aka just a short info page
without any articles. I personally don't use it at all, as we'll see later on, I
customized my landing page to show all the needed info.

# Basic configuration

It's time to look at other files. `Makefile` and `tasks.py` are for automation,
remember the questions of `pelican-quickstart` about uploading using ssh or ftp
? Those responses would be used to generate the appropriate commands in these 2
files so we can upload our blog to the server in a heart beat. I actually never
touched `tasks.py` since I only use `Makefile`. The default generated one is
more than enough for me at the beginning. I only added a couple of things much
later on once I gradually added different tools to optimize the build of my
blog.

The very big part of a Pelican project is the configuration sit inside
`pelicanconf.py`, it's a set and forget sort of thing. The `publishconf.py`
extends `pelicanconf.py` and add some necessary info for building a _publish_
version of the blog. The default configurations can be leave as is and are
simple enough that a quick glance of the documentation is all that's needed.
I'll talk about the ones that are a bit tricky to work with.

The commonly refered as URL settings on Pelican documentation allows me to
structure the _output_ directory, this is what I want since I'm a bit obsessed
with organizing things. There's 2 types of this setting: `*_URL` and
`*_SAVE_AS`. The `*_SAVE_AS` is used, per the name say, as the path for saving
files. It controls where exactly in the _output_ folder I want to save my
articles and pages. For example I can put something like `author/abc.html` for
`AUTHOR_SAVE_AS`, and the author page will be saved as such. The `*_URL` is used
as the path to reference such file in other Pelican generated files. It actually
bugged my head a bit when I first read the documentation as it's not clear what
it does and why it's slightly different from `*_SAVE_AS` path. Basically, if you
put `author` for `AUTHOR_URL`, now in the landing page if there's a generated
link to the author page, it will use `author` as the path, instead of
`author/abc.html`. This shortens the path and allows you, for example configure
nginx server to auto search for `path/index.html` whenenver receiving `path`.
More on that later, but if you're not so sure about this at first, the rule of
thumb is to set `*_SAVE_AS` to `full/path/to/file/index.html` and `*_URL` to
`full/path/to/file`. I set both `AUTHOR_SAVE_AS` and `AUTHORS_SAVE_AS` to
`False` since I don't use the author page at all, there's no need to save it,
I'm the sole author of my blog anyway.

Now there's the `Date` metadata in each article. Sorting by date is doable on my
blog, but what if I wanna sort it in my filesystem ? I can do it by putting the
date on the filename of my articles in _content_ directory, but how to tell
Pelican to use the filename for the metadata ? Luckily there's
`FILENAME_METADATA` for this exact purpose. Mine is

`'(?P<date>\d{4}-\d{2}-\d{2})-(?P<slug>.*)'`

which is Regular Expression (RegEx) saying that, take the first 3 strings
separated by `-` as year, month, date, and whatever left as
[slug](https://wordpress.com/go/business-website-guidance/what-is-a-slug/). The
`Data` metadata format is flexible, but I highly recommend to use ISO format
(YYYY-mm-dd) because it's not ambiguous, plus the filename can be sorted
naturally by filesystems.

The last configuration I'll talk about here is `PAGINATION_PATTERNS`. Pelican
has a pagination system, which if we chose default during `pelican-quickstart`,
will be set to 10. This is the maximum number of listed articles per page, for
example when visiting `/blog`. The `PAGINATION_PATTERNS` allows to specify how
and where to save the pagination pages, and only needed if we reach the maximum
number of articles per page. If you're not there yet, skip it, come back when
you have enough articles, copy paste my configuration and see the effect it
makes in _output_ folder.

Now with all these settings in place, you can start to write and see your blog
locally with `make devserver`, make sure you have `Makefile` installed. Give it
a go !
