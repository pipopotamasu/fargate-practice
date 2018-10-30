FROM node:8.12-alpine

ENV APP_HOME /nuxt
WORKDIR $APP_HOME

ENV NODE_ENV production
# copy repo files into docker
COPY . $APP_HOME

# IMPORTANT!: specify host
ENV HOST 0.0.0.0
EXPOSE 3000

# this command is execed when build container
RUN yarn install
RUN yarn run build

COPY .nuxt $APP_HOME

# this command is execed after building container
CMD ["yarn", "run", "start"]