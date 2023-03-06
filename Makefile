## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## run/api: run the cmd/api application
run/api:
	go run ./cmd/api

## run/db: run the db-postgreSQL application
run/db:
	docker run --rm --name psg -e POSTGRES_USER=greenlight -e POSTGRES_PASSWORD=pa55word -e POSTGRES_DATABASE=greenlight -d -p 5432:5432 postgres
	sleep 5 && cat greenlight_dump.sql | docker exec -i psg psql -U greenlight -d greenlight
## rororor
stop:
	docker exec psg pg_dump -U greenlight greenlight > greenlight_dump.sql
	docker stop psg
exec:
	docker exec -it psg psql -U greenlight -d greenlight
up: confirm
	@echo 'Running up migrations...'
	migrate -path=./migrations -database=postgres://greenlight:pa55word@localhost:5432/greenlight?sslmode=disable up
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]