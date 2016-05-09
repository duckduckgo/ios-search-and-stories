# Contributing

We are excited that you want to help make DuckDuckGo Search & Stories better. Some of the best features of DuckDuckGo came from the community!

* If there isn't already an open issue that describes your bug or feature, please submit one.
  * If you're submitting a **bug**, please describe a way we can reproduce the problem and the affected versions.
  * If you're submitting a **feature** (cool!), make sure you contact us beforehand so that you aren't duplicating effort.

## Set Up
Before building the app you must have mogenerator installed. You can check if it is installed by typing "mogenerator" in the terminal. If the output is "0 machine files and 0 human files generated.
" you are set. If it says invalid command you can find out how to install mogenerator from [this website] (https://rentzsch.github.io/mogenerator/).

The App Store version of the app uses a font, *ProximaNova*, whose license prohibits its inclusion in this repository. Because of this, the Xcode build will fail, unless you replace it with something else. [*Open Sans*](http://opensans.com) is a nice open-source option.

After copying the font to the Xcode project, you'll need to change any references to it, including source code and xibs (use the Find navigator to help here!), and remove the 4 *ProximaNova* references in the "Copy Bundle Resources" section of the project's Build Phases (there are a lot of resouces&mdash;filter on `ProximaNova` to make this faster).

### Submodules
This repository has submodules, please init them before building by running this command on terminal:

```console
git submodule update --init --recursive
```

## Changes
* **Bugs** fork the repository on GitHub and create a topic branch from **master** with your GitHub username in the branch name like:
  `git checkout -b nilnilnil/segfault-stories-swipe origin/master`
* **Features** fork the repository on GitHub and create a topic branch from **develop** with your GitHub username in the branch name like:
  `git checkout -b nilnilnil/sooper-feature origin/develop`
* Add tests that check what you've done.
* PRs with failing tests will not be accepted.

**Commit format:**
````
    (#GH_ISSUE) Make the example in CONTRIBUTING imperative and concrete.

    Without this patch applied the example commit message in the CONTRIBUTING
    document is not a concrete example.  This is a problem because the
    contributor is left to imagine what the commit message should look like
    based on a description rather than an example.  This patch fixes the
    problem by making the example concrete and imperative.

    The first line is a real life imperative statement with a GitHub issue #.
    The body describes the behavior without the patch, why this is a problem,
    and how the patch fixes the problem when applied.
````

## Additional Resources

* [Issues](https://github.com/duckduckgo/ios/issues)
* [General info](http://help.dukgo.com/customer/portal/articles/378777-contributing)
* [Chat](https://dukgo.com/blog/using-pidgin-with-xmpp-jabber)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
* [General GitHub documentation](http://help.github.com/)
