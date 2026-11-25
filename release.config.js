module.exports = {
  "branches": ["main", "main-lts"],
  "plugins": [
    ["@semantic-release/commit-analyzer", {
      "preset": "angular",
      "parserOpts": {
        "noteKeywords": ["BREAKING CHANGE", "BREAKING CHANGES", "BREAKING"]
      }
    }],
    ["@semantic-release/release-notes-generator", {
      "preset": "angular",
    }],
    ["@semantic-release/changelog", {
      "changelogFile": "CHANGELOG.md"
    }],
    "@semantic-release/github",
    [
      "@google/semantic-release-replace-plugin",
      {
        "replacements": [
          {
            "files": ["Sources/Amplitude/AMPConstants.m"],
            "from": "kAMPVersion = @\".*\"",
            "to": "kAMPVersion = @\"${nextRelease.version}\"",
            "results": [
              {
                "file": "Sources/Amplitude/AMPConstants.m",
                "hasChanged": true,
                "numMatches": 1,
                "numReplacements": 1
              }
            ],
            "countMatches": true
          },
        ]
      }
    ],
    ["@semantic-release/git", {
      "assets": ["Sources/Amplitude/AMPConstants.m", "CHANGELOG.md"],
      "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    ["@semantic-release/exec", {
      "successCmd": "appledoc . && rsync -av doc/html/*  Amplitude-iOS-gh-pages/ && cd Amplitude-iOS-gh-pages && git add . && git commit -am '${nextRelease.version}' && git push"
    }],
  ],
}
