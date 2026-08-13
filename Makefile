SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help setup build up down restart logs validate reload status test backup clean

help:
	@printf '%s\n' \
	  'make setup     Prepare local directories and .env' \
	  'make build     Build pinned WAF image' \
	  'make up        Start WAF' \
	  'make down      Stop WAF' \
	  'make logs      Follow container logs' \
	  'make validate  Build + validate Nginx/ModSecurity/CRS' \
	  'make reload    nginx -t then graceful reload' \
	  'make status    Container health/version status' \
	  'make test      Run HTTP/WAF smoke tests' \
	  'make backup    Archive configuration' \
	  'make clean     Remove stopped containers only'

setup:
	./scripts/setup.sh

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart waf

logs:
	docker compose logs -f --tail=200 waf

validate:
	./scripts/validate.sh

reload:
	./scripts/reload.sh

status:
	./scripts/status.sh

test:
	./tests/smoke.sh

backup:
	./scripts/backup.sh

clean:
	docker compose rm -f
