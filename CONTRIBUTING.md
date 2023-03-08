# Contribution Guide

Thanks for your interest in the moxxmpp XMPP library! This document contains guidelines and guides for working on the moxxmpp codebase.

## Contributing

If you want to fix a small issue, you can just fork, create a new branch, and start working right away. However, if you want to work
on a bigger feature, please first create an issue (if an issue does not already exist) or join the [development chat](xmpp:moxxy@muc.moxxy.org?join) (xmpp:moxxy@muc.moxxy.org?join)
to discuss the feature first.

Before creating a pull request, please make sure you checked every item on the following checklist:

- [ ] I formatted the code with the dart formatter (`dart format`) before running the linter
- [ ] I ran the linter (`dart analyze`) and introduced no new linter warnings
- [ ] I ran the tests (`dart test`) and introduced no new failing tests
- [ ] I used [gitlint](https://github.com/jorisroovers/gitlint) to ensure propper formatting of my commig messages

If you think that your code is ready for a pull request, but you are not sure if it is ready, prefix the PR's title with "WIP: ", so that discussion
can happen there. If you think your PR is ready for review, remove the "WIP: " prefix.
