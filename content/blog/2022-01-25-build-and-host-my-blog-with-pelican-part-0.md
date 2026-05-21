+++
title = "Build & host my blog with Pelican (part 0)"

[taxonomies]
tags = ["build", "blog", "pelican", "python"]
+++

I've been writing since a couple of years back, sort of a diary activity or sometimes just to take note what I learned. I posted some of it on Medium. But Medium is not for anything else but writing, and I make other stuffs too 😢

Then there's WordPress, but I didn't need the dynamic nature, nor any database, it just seemed way overkill to host one. To be fair, I guess if it was a blog for my mom, maybe I'll use it.

<!-- more -->

# Why Pelican ?

What really tipped me off the edge is, although they provide you an all-in-one solution to write, their text editors usually suck 👎 If I'm gonna host the blog myself, I must be able to write on whatever I want. Since I write notes in Markdown, publish markdowns to my blog makes sense. I've been following [Eevee's blog](https://eev.ee/) (she makes amazing stuffs btw, as of the moment of this writing I took a lot of assets from her blog) and really enjoyed the layout. So I figured, I'd see how she built it. That's when I came across [Pelican](https://blog.getpelican.com/) - a [static site generator (SSG)](https://jamstack.org/generators/), and because the name seems cool, plus its configuration and plugins are in Python (which I don't like but quite comfortable with, meaning I'd be able to hack around if needed), I decided to give it a try.

# A very first look

*All steps are done in Linux environment.*

*The doc for installation and quick-start guide is quite short and very well written, if you know nothing about Pelican, make sure you finish it before reading any further (super highly recommend that you install Pelican with virtualenv).*

I followed the installation doc and quick-start guide to get a first look inside a Pelican project. It was pretty easy using `pelican-quickstart` CLI and leaving most of the options as default. Before looking into any configurations, I tried to well understand the concepts and folder structure. On retrospect, it surely helped me to debug configurations whenever things go south.

```sh
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

An SSG basically takes what inside `content` and generate an `output` directory containing `.html` files for displaying the content in the browser, all the other files are for configurations and automation. The `content` directory is where I will put my blog articles written in `.md`, in each of which there's some metadata I need to specify, such as title, date, category...etc. I think Pelican supports several text file extensions, but I only use Markdown anyway.

Look into the `output` folder, it's clear that `post1.md` got converted into `post1.html`, `index.html` is obviously the landing page. How about the rest ? I came to realize that those pages sort the metadata that we explicitly defined, e.g. `author/*.html` gives us the list of article by that author and `authors.html` links to each `author/*.html` page. By default, I don't think the basic landing page show me any link to these metadata pages, but with a running the dev server, I could access by typing the URL into the browser, e.g. `/authors`, and so on.

I referred to *articles* (as in `post1.md`), and then *pages*. Both are concepts of Pelican. Pages are usually for listing some information while article is a post on the blog. That is for example the *contact-me* or *about-me* page, which is just a short info page without any articles. I personally don't use them at all, since I will be customizing my landing page to show all the needed info.

# Basic configuration

It's time to look at other files. `Makefile` and `tasks.py` are for automation, remember the questions of `pelican-quickstart` about uploading using ssh or ftp ? Those responses would be used to generate the appropriate commands in these 2 files, so I can upload my blog to the server in a heart beat. I actually never touched `tasks.py` since I only use `Makefile`. The default generated one is more than enough for me at the beginning. I only added a couple of things much later on once I gradually added different tools to optimize the building process.

The very big part of a Pelican project is the configuration sit inside `pelicanconf.py`, it's a set and forget sort of thing. The `publishconf.py` extends `pelicanconf.py` and add some necessary info for building a *publish* version of the blog. The default configurations can be leave as is and are simple enough. Let's talk about those that I struggled since they are a bit tricky to work with.

The commonly referred as URL settings on Pelican documentation allows me to structure the `output` directory (Great ! I'm a bit obsessed with organizing things). There are 2 types of URL setting: `*_URL` and `*_SAVE_AS`. The `*_SAVE_AS` is, as the name say, the path for saving files. It controls where exactly in the `output` folder I want to save my articles and pages. For example, I can put something like `author/index.html` for `AUTHOR_SAVE_AS`, and the author page will be saved as such. The `*_URL` is used as the URL's path to reference such file in other Pelican generated files. IMHO, the documentation on this setting wasn't very clear regarding what it does and why it's slightly different from the `*_SAVE_AS` path, I struggled to understand it. Basically, if I put `author` for `AUTHOR_URL`, now every time Pelican generates a link to the author page (it automatically does this in some cases, like a landing page), it will use `author` as the path, instead of `author/index.html`. This shortens the path, for use cases such as configuring nginx server to auto search for `path/index.html` whenever receiving `path`. More on that later, but if you're not so sure about this at first, the rule of thumb is to set `*_SAVE_AS` to `full/path/to/file/index.html` and `*_URL` to `full/path/to/file`. I set both `AUTHOR_SAVE_AS` and `AUTHORS_SAVE_AS` to `False` since I don't use the author page at all, there's no need to save it, I'm the sole author of my blog anyway.

Next, I look at the `Date` metadata in each article. Sorting by date is doable on my blog, but what if I wanna sort it in my file system ? Writing the date in 2 places is cumbersome. Luckily, I can just put the date on the filename of my articles in `content` directory and tell Pelican to use it for metadata by using the option `FILENAME_METADATA`. Mine is

```python
'(?P<date>\d{4}-\d{2}-\d{2})-(?P<slug>.*)'
```

Which is Regular Expression (Regex) saying that, take the first 3 strings separated by `-` as year, month, date, and whatever left as [slug](https://wordpress.com/go/business-website-guidance/what-is-a-slug/). The `Data` metadata format is flexible, but I highly recommend to use ISO format (YYYY-mm-dd) because it's not ambiguous, plus the filename can be sorted naturally by file systems.

The last configuration I'll talk about here is `PAGINATION_PATTERNS`, Pelican pagination system. Its default value during `pelican-quickstart` is 10. This is the maximum number of listed articles per page at the index. The `PAGINATION_PATTERNS` allows specifying how and where to save the pagination pages, and only needed if I reach the maximum number of articles per page. If you're not there yet, skip it, come back when you have enough articles, copy paste my configuration and see the effect it makes in `output` folder.

With all these settings in place, I can start to write and see my blog locally with `make devserver`, make sure you have `Makefile` installed to build your blog. Give it a go !
