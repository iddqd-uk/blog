# Static Blog

[![Test][badge_test]][link_actions]
[![Publish][badge_publish]][link_actions]
![Last commit][badge_last_commit]
[![Discussions][badge_discussions]][link_issues]

Static blog, generated using [hugo][hugo] ([theme docs](https://docs.stack.jimmycai.com/writing/)).

## System requirements

- `docker >= 18.0`
- `make >= 4.1`

## Usage

### Start local server

For a starting web-server with auto-reload feature, run:

```bash
$ make start
```

### New post

To make a new blog post, execute in your terminal:

```bash
$ make post
```

## Deploy

Any changes, pushed into `master` branch will be automatically deployed _(be careful with this, think **twice** before pushing)_.

[badge_test]:https://img.shields.io/github/workflow/status/hook-sh/blog/tests/master?label=tests&maxAge=60&logo=github
[badge_publish]:https://img.shields.io/github/workflow/status/hook-sh/blog/publish/master?label=publish&maxAge=60&logo=github
[badge_discussions]:https://img.shields.io/github/issues-raw/hook-sh/blog.svg?label=discussions&maxAge=60
[badge_last_commit]:https://img.shields.io/github/last-commit/hook-sh/blog/master?label=last%20update&maxAge=60
[link_issues]:https://github.com/hook-sh/blog/issues
[link_actions]:https://github.com/hook-sh/blog/actions
[hugo]:https://gohugo.io/
