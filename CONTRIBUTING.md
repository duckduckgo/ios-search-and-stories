# Contributing

Thanks for helping us make DuckDuckGo for Android! DuckDuckHack has been a
great success and so we've taken the steps necessary to open sourcing our apps.

## Getting Started

* If **you are a developer**, you're in the right place!
* If **you are not a developer**, there is still a lot you can do at our [ideas site](http://ideas.duckduckhack.com/) like suggest and comment on prospective features / ideas.
* Both of these roles are very valuable and will help direct community efforts.

* All developers should make sure to have a [GitHub account](https://github.com/signup/free)
* If there isn't already an open issue that describes your bug or feature, submit one.
  * If you're submitting a bug, please describe a way we can reproduce the issue(s).
  * Be sure to add the version you're experiencing the issue on.
  * If you're submitting a feature (cool!), make sure you contact us before you do any work to ensure that
    * You aren't duplicating efforts
    * It is aligned with the goal of our apps
* Some of the best features of DuckDuckGo came from the community; so stay in touch!


## Making Changes

## Bugs
* Fork the repository on GitHub and create a topic branch from **master** with your GitHub username in the branch name like:
  * `git checkout -b nilnilnil/NPE-stories-longpress origin/master`

## Features
* Fork the repository on GitHub and create a topic branch from **develop** with your GitHub username in the branch name like:
  * `git checkout -b nilnilnil/sooper_feature origin/develop`

* Don't make huge commits.
* Check whitespace with `git diff --check` before committing.

## Commit messages

````
    (#99999) Make the example in CONTRIBUTING imperative and concrete

    Without this patch applied the example commit message in the CONTRIBUTING
    document is not a concrete example.  This is a problem because the
    contributor is left to imagine what the commit message should look like
    based on a description rather than an example.  This patch fixes the
    problem by making the example concrete and imperative.

    The first line is a real life imperative statement with a ticket number
    from our issue tracker.  The body describes the behavior without the patch,
    why this is a problem, and how the patch fixes the problem when applied.
````

* Add tests that check what you've done.
* PRs with failing tests will not be accepted.

# Additional Resources

* [DuckDuckGo contribution information](http://help.dukgo.com/customer/portal/articles/378777-contributing)
* [DuckDuckGo for Android issues]()
* [DuckDuckGo for Android LICENSE]()
* [DuckDuckGo for Android chat](https://dukgo.com/blog/using-pidgin-with-xmpp-jabber)
* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
