FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV CI=true
RUN corepack enable

FROM base AS build
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run -r build
RUN pnpm deploy --filter=service-b --prod /prod/service-b

FROM base AS service-b
COPY --from=build /prod/service-b /prod/service-b
WORKDIR /prod/service-b
EXPOSE 3001
CMD [ "node", "dist/main" ]

