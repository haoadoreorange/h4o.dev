PY?=python3
PELICAN?=pelican
PELICANOPTS=

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/output
OUTPUTPUBLISH=output-publish
OUTPUTPUBLISHDIR=$(BASEDIR)/$(OUTPUTPUBLISH)
CONFFILE=$(BASEDIR)/pelicanconf.py
PUBLISHCONF=$(BASEDIR)/publishconf.py
PUBLISHCONFLOCAL=$(BASEDIR)/publishconf.local.py
SASS=$(BASEDIR)/tools/dart-sass/sass-linux-amd64
SASSARGS=--no-source-map theme/static/sass/all.scss theme/static/css/all.css
MINIFY=$(BASEDIR)/tools/minify/minify-linux-amd64

DEBUG ?= 0
ifeq ($(DEBUG), 1)
	PELICANOPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE), 1)
	PELICANOPTS += --relative-urls
endif

SERVER ?= "0.0.0.0"

PORT ?= 0
ifneq ($(PORT), 0)
	PELICANOPTS += -p $(PORT)
endif


help:
	@echo 'Makefile for a pelican Web site                                           '
	@echo '                                                                          '
	@echo 'Usage:                                                                    '
	@echo '   make html                           (re)generate the web site          '
	@echo '   make clean                          remove the generated files         '
	@echo '   make regenerate                     regenerate files upon modification '
	@echo '   make publish                        generate using production settings '
	@echo '   make serve [PORT=8000]              serve site at http://localhost:8000'
	@echo '   make serve-global [SERVER=0.0.0.0]  serve (as root) to $(SERVER):80    '
	@echo '   make devserver [PORT=8000]          serve and regenerate together      '
	@echo '   make devserver-global               regenerate and serve on 0.0.0.0    '
	@echo '                                                                          '
	@echo 'Set the DEBUG variable to 1 to enable debugging, e.g. make DEBUG=1 html   '
	@echo 'Set the RELATIVE variable to 1 to enable relative urls                    '
	@echo '                                                                          '
	
clean:
	[ ! -d "$(OUTPUTDIR)" ] || rm -rf "$(OUTPUTDIR)"; [ ! -d "$(OUTPUTPUBLISHDIR)" ] || rm -rf "$(OUTPUTPUBLISHDIR)"
	
sass:
	"$(SASS)" $(SASSARGS)
	
watch-scss:
	"$(SASS)" -w $(SASSARGS)

html: sass
	"$(PELICAN)" "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)
	
# regenerate:
# 	"$(PELICAN)" -r "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

serve:
	"$(PELICAN)" -l "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

serve-global:
	"$(PELICAN)" -l "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS) -b $(SERVER)
	
watch-pelican:	
	"$(PELICAN)" -lr "$(INPUTDIR)" -o "$(OUTPUTDIR)" -s "$(CONFFILE)" $(PELICANOPTS)

devserver:
	make -j2 watch-scss watch-pelican
	
watch-pelican-global:
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS) -b $(SERVER)

devserver-global:
	make -j2 watch-scss watch-pelican-global

html-publish: sass
	"$(PELICAN)" "$(INPUTDIR)" -s "$(PUBLISHCONF)" $(PELICANOPTS)
	
html-publish-local: sass
	"$(PELICAN)" "$(INPUTDIR)" -s "$(PUBLISHCONFLOCAL)" $(PELICANOPTS)	
	
html-release: html-publish
	"$(MINIFY)" -o . -r $(OUTPUTPUBLISH)

.PHONY: help clean sass watch-sass html serve serve-global watch-pelican devserver watch-pelican-global devserver-global \
		html-publish html-publish-local html-release
