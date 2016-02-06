
# Change Log

## [1.0.0](https://github.com/qbwc/qbwc/tree/2.0.4) (2016-12-04)
[Full Changelog](https://github.com/qbwc/qbwc/compare/2.0.3...2.0.4)

**Upgrading:**

Upgrading from previous versions requires running new migrations.

Run the generator:

`rails generate qbwc:install`

Then the migrations:

`rake db:migrate`
`rake RAILS_ENV=test db:migrate`

In production, ensure that no jobs are queued, then:
`rake RAILS_ENV=production db:migrate`

**Fixed bugs:**

- Placeholder [\#156](https://github.com/qbwc/qbwc/issues/156)

**Closed issues:**

- Placeholder [\#129](https://github.com/qbwc/qbwc/issues/129)

**Merged pull requests:**

- Placeholder [\#235](https://github.com/qbwc/qbwc/pull/235) ([mamnun](https://github.com/mamnun))

