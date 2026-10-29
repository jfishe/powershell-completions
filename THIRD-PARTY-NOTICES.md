# Third-Party Notices

This repository is licensed under the MIT License (see `LICENSE`). It includes
or adapts the third-party material below.

## winget-cli tab completion

The `winget` argument completer in `Profile.Completions.ps1` is copied from
[microsoft/winget-cli `doc/Completion.md`][winget-completion].

```text
MIT License

Copyright (c) Microsoft Corporation. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## No Clocks Blog: lazy loading tab completion scripts

The lazy-loading approach in `Profile.Completions.ps1` is adapted from Jimmy
Briggs' (No Clocks, LLC) post
[Lazy Loading Tab Completion Scripts in PowerShell][lazy_loading]. The post
states no license. The code here is an independent implementation of the idea:
it uses per-command loaders rather than the post's catch-all completer.

## Generated bash completion files

`copilot-completion.sh` and `pandoc-completion.sh` are generated locally, as the
README describes, and are not distributed with this repository. They keep their
upstream licenses:

- GitHub Copilot CLI: Copyright (c) Microsoft Corporation.
- [pandoc][pandoc]: GPL-2.0-or-later, Copyright (c) John MacFarlane.

## Runtime dependencies

The modules and tools these completions load (posh-git, PSBashCompletions,
VimTabCompletion, WSLTabCompletion, bat, chezmoi, ripgrep, pixi, uv,
pandoc, GitHub Copilot CLI, winget) are installed separately. They are not
included here and are covered by their own licenses.

[lazy_loading]: https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell
[pandoc]: https://github.com/jgm/pandoc/blob/main/COPYRIGHT
[winget-completion]: https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md
