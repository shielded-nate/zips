# Zcash Improvement Proposals

## What are ZIPs?

Zcash Improvement Proposals (ZIPs) are the way to:

- propose new features for the [Zcash cryptocurrency](https://z.cash/) and their rationale,
- specify the implementation details of the feature,
- collect community input on the proposal, and
- document design decisions.

## Contributing

The authors of a ZIP are responsible for building consensus within the community
and documenting / addressing dissenting opinions.

Anyone can write a ZIP! We encourage community contributions and decentralization
of work on the Zcash protocol. If you'd like to bounce ideas off people before formally
writing a ZIP, we encourage it! Visit the
[ZcashCommunity Discord chat](https://discord.gg/kdjfvps) to talk about your idea.

Participation in the Zcash project is subject to a
[Code of Conduct](https://github.com/zcash/zcash/blob/master/code_of_conduct.md).

The Zcash protocol is documented in its
[Protocol Specification](https://zips.z.cash/protocol/protocol.pdf).

To start contributing, first read [ZIP 0](zip-0000.md) which documents the ZIP process.
Then clone [this repo](https://github.com/zcash/zips) from GitHub, and start adding
your draft ZIP, formatted either as reStructuredText or as Markdown, into the `zips/`
directory.

For example, if using reStructuredText, use a filename matching `zips/draft-*.rst`.
Use `make` to check that you are using correct
[reStructuredText](https://docutils.sourceforge.io/rst.html) or
[Markdown](https://pandoc.org/MANUAL.html#pandocs-markdown) syntax,
and double-check the generated `rendered/draft-*.html` file before filing a Pull Request.
See [here](https://github.com/zcash/zips/blob/main/protocol/README.rst) for the project
dependencies.

## License

Unless otherwise stated in this repository's individual files, the contents of this
repository are released under the terms of the MIT license. See
[COPYING](https://github.com/zcash/zips/blob/main/COPYING.rst) for more information or
see <https://opensource.org/licenses/MIT>.
