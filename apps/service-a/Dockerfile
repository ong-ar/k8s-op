FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV CI=true
RUN corepack enable

FROM base AS build
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run -r build
RUN pnpm deploy --filter=service-a --prod /prod/service-a

FROM base AS service-a
COPY --from=build /prod/service-a /prod/service-a
WORKDIR /prod/service-a
EXPOSE 3000
CMD [ "node", "dist/main" ]

