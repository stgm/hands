# Hands

## Getting started

Requires Ruby 4.0.5 (see `.ruby-version`) and `openssl` on the PATH.

Run once after cloning:

```
bin/setup
```

This installs the gems into rv's gem directory for Ruby 4.0.5, generates a local
HTTPS certificate in `config/ssl`, creates the SQLite development database, loads
the schema and the seed data, and then starts the server.

If you have an older checkout that installed gems into `vendor/bundle`, delete
that directory and `.bundle/config` before running `bin/setup` again.

After that, start the server with:

```
bin/dev
```

The app runs at https://localhost:3001. The development certificate is
self-signed, so the browser shows a warning on the first visit.

## Development data

`db/seeds.rb` creates a `demo` course domain and a set of accounts:
`admin@example.com`, `teacher@example.com`, `ta@example.com`, and
`student@example.com` (plus `student1`–`student3`).

Login uses a one-time code sent by email. In development, mail is written to
`tmp/mails` instead of being delivered, so read the code from the newest file
there.

## Tests

```
bin/rails test
```
