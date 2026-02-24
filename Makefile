.PHONY: dev install clean typecheck db-types test

dev:
	@pnpm dev

install:
	@pnpm install

clean:
	@pnpm clean

typecheck:
	@pnpm typecheck

db-types:
	@pnpm db:types

test:
	@pnpm test

setup:
	@./scripts/setup.sh

mobile:
	@pnpm --filter=@pideloo/mobile dev

api:
	@pnpm --filter=@pideloo/api dev

web:
	@pnpm --filter=@pideloo/web dev
