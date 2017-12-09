
# Change Log

## [1.1.0](https://github.com/qbwc/qbwc/releases/tag/v1.1.0) (2016-03-02)
[Full Changelog](https://github.com/qbwc/qbwc/compare/1.0.0...1.1.0)

**Fixed bugs:**

- Support Rails 5. [\#100](https://github.com/qbwc/qbwc/pull/100) ([rchekaluk](https://github.com/rchekaluk)) [\#117](https://github.com/qbwc/qbwc/pull/117) ([lostapathy](https://github.com/lostapathy))
- Clarify documentation regarding top-level tag in response hash. [\#91](https://github.com/qbwc/qbwc/pull/91)  ([steintr](https://github.com/steintr))
- Fix Rails 5 deprecations. [\#97](https://github.com/qbwc/qbwc/pull/97) ([nicholejeannine](https://github.com/nicholejeannine))

**New features:**

- Log qbxml_response closer to the top of \#process_response. [\#90](https://github.com/qbwc/qbwc/pull/90) ([steintr](https://github.com/steintr))


## [1.0.0](https://github.com/qbwc/qbwc/releases/tag/v1.0.0) (2016-03-02)
[Full Changelog](https://github.com/qbwc/qbwc/compare/0.1.0...1.0.0)

**Upgrading:**

Upgrading from previous versions requires running new migrations.

Run the generator:

`rails generate qbwc:install`

Then the migrations:

`rake db:migrate`
`rake RAILS_ENV=test db:migrate`

In production, ensure that no jobs are queued, then:
`rake RAILS_ENV=production db:migrate`

The `requests` and `should_run?` methods of `QBWC::Worker` now take three parameters: `job`, `session`, and `data`. Any workers that implement these methods should be updated to accept the additional parameters.

**Fixed bugs:**

- Removed 1000-character restriction on list of pending jobs [\#76](https://github.com/qbwc/qbwc/pull/76) ([rchekaluk](https://github.com/rchekaluk))

**New features:**

- App name and FileID provided to QuickBooks can now be overridden by implementing `app_name` and `file_id` in the generated QbwcController. [\#72](https://github.com/qbwc/qbwc/pull/72) ([r38y](https://github.com/r38y))
- `requests` and `should_run?` now receive the session and data Hash as arguments. This allows for greater control over which requests happen in a run. [\#80](https://github.com/qbwc/qbwc/pull/80) ([bkroeker](https://github.com/bkroeker))
- Added the `session_complete_success` configuration to specify a block to execute when the session completes.  [\#80](https://github.com/qbwc/qbwc/pull/80) ([bkroeker](https://github.com/bkroeker))
- Added some indexes to qbwc_jobs for better performance with many jobs are defined. [\#80](https://github.com/qbwc/qbwc/pull/80) ([bkroeker](https://github.com/bkroeker))
