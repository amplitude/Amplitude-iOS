module.exports = {
  "branches": ["release-pipeline"], // @TODO: Replace with master
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
            "files": ["jooohhn-Amplitude.podspec"],
            "from": "amplitude_version = \".*\"",
            "to": "amplitude_version = \"${nextRelease.version}\"",
            "results": [
              {
                "file": "jooohhn-Amplitude.podspec", // @TODO: Replace with Amplitude.podspec
                "hasChanged": true,
                "numMatches": 1,
                "numReplacements": 1
              }
            ],
            "countMatches": true
          },
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
      "assets": ["jooohhn-Amplitude.podspec", "Sources/Amplitude/AMPConstants.m", "CHANGELOG.md"], // @TODO: Replace with Amplitude.podspec
      "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    ["@semantic-release/exec", {
      "publishCmd": "pod trunk push jooohhn-Amplitude.podspec", // @TODO: Replace with Amplitude.podspec
    }],
  ],
}
