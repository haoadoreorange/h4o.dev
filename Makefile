include Makefile.env

deploy:
	ssh -t -i $(SSH_ID) $(SSH_USER)@$(SSH_HOST) 'bash -s' < deploy.sh

dev:
	zola serve --drafts

build:
	zola build

release: build
	rsync -e "ssh -i $(SSH_ID)" -aPhhvzc --chown="$(SSH_USER)":nginx --chmod=D2750,F640 --include tags --cvs-exclude --delete public/ "$(SSH_USER)@$(SSH_HOST):/usr/share/nginx/html"

.PHONY: deploy dev build release
