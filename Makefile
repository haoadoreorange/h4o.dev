install: # dependencies
	@if type cargo >/dev/null 2>&1; then \
		cargo install --locked --git https://github.com/getzola/zola; \
	elif type pacman >/dev/null 2>&1; then \
		sudo pacman -S --noconfirm zola; \
	else \
		printf 'error: No supported package manager\n' >&2; \
		exit 1; \
	fi

uninstall: # dependencies
	@if { cargo install --list | grep -qF zola; } 2>/dev/null; then \
		cargo uninstall zola; \
	elif type pacman >/dev/null 2>&1; then \
		sudo pacman -Rns --noconfirm zola; \
	else \
		printf 'error: No supported package manager\n' >&2; \
		exit 1; \
	fi

deploy: # nginx
	@ssh blog 'sh -s' < deploy.sh # stream script to remote shell via stdin

dev:
	zola serve --drafts

build:
	zola build

release: # to nginx
	@set -eu; \
	blogroot=/usr/share/nginx/html/h4o.dev; \
	: cannot chown in rsync, it always require sudo even with owner; \
	: --cvs-exclude skips 'tags' but zola generates it; \
	rsync --mkpath -aPhhvzc --delete --include tags --exclude '*.git' --cvs-exclude --chmod=D750,F640 public/ "blog:$$blogroot"; \
	: remote sees: chown -R "$USER:nginx" '/path'; \
	ssh blog chown -R '"$$USER:nginx"' "'$$blogroot'"

new:
	@set -eu; \
	if [ -z "$(s)" ] || [ -z "$(t)" ]; then echo "Usage: make new s='section' t='title'"; exit 1; fi; \
	date=$$(date +%Y-%m-%d); \
	slug=$$(printf '%s' "$(t)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$$//'); \
	file="content/$(s)/$$date-$$slug.md"; \
	printf '+++\ntitle = "%s"\ndraft = true\n+++\n' "$(t)" > "$$file"; \

.PHONY: install uninstall deploy dev build release new
