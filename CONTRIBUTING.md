## Contributing

To avoid duplicates, please search existing issues before reporting a
new one.

Github Issues is intended for reporting bugs and feature suggestions. If
you have a question or need support, please use [Stack
Overflow](https://stackoverflow.com/questions/tagged/calabash) or join
the conversation on [Gitter](https://gitter.im/calabash/calabash0x?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

## How to Contribute

This repository uses git-flow.

* All pull requests should be based off the `develop` branch.
* Contributors should never change the version of the product.
* Contributors should never commit code signing changes.

### Best Practices

* [Good commit messages](http://chris.beams.io/posts/git-commit/)
* [Git Flow:  Step-by-Step](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
* [Git Best Practices](http://justinhileman.info/article/changing-history/)

## Etiquette and Code of Conduct

All contributors must adhere to the [Microsoft Open Source Code of
Conduct](https://opensource.microsoft.com/codeofconduct/). For more
information see the [Code of Conduct
FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact
opencode@microsoft.com with any additional questions or comments.

## Legal

Users who wish to contribute will be prompted to sign a Microsoft
Contributor License Agreement (CLA). A copy of the CLA can be found at
https://cla.microsoft.com/cladoc/microsoft-contribution-license-agreement.pdf.

Please consult the LICENSE file in this project for copyright and
license details.

## Releasing

After the release branch is created:

* No more features can be added.
* All in-progress features and un-merged pull-requests must wait for the next release.
* You can, and should, make changes to the documentation.

The release pull request ***must*** be made against the _master_ branch.

```
$ git co -b release/3.2.1

1. Update the CHANGELOG.md.
2. **IMPORTANT** Bump the version in iOSDeviceManager/Commands/VersionCommand.m
3. **IMPORTANT** Bump the version in the README.md badges.
4. Review the README.md and update content as necessary.

$ git push -u origin release/3.2.1

**IMPORTANT**

1. Make a pull request on GitHub on the master branch.
2. Wait for CI to finish.
3. Merge pull request.

$ git co master
$ git pull
$ bin/git-tag.sh

$ git co develop
$ git merge --no-ff release/3.2.1
$ git push

$ git branch -d release/3.2.1

Announce the release on the public channels.
```

