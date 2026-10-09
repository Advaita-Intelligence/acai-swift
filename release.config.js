module.exports = {
  "branches": ["main", "1.1.x"],
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
    [
      "@semantic-release/github", {
        "assets": [
          { "path": ".build/artifacts/AcaiSwift.xcframework.zip" },
          { "path": ".build/artifacts/AcaiSwiftNoUIKit.xcframework.zip" },
        ]
    }],
    [
      "semantic-release-replace-plugin",
      {
        "replacements": [
          {
            "files": ["AcaiSwift.podspec"],
            "from": "acai_version = \".*\"",
            "to": "acai_version = \"${nextRelease.version}\"",
            "results": [
              {
                "file": "AcaiSwift.podspec",
                "hasChanged": true,
                "numMatches": 1,
                "numReplacements": 1
              }
            ],
            "countMatches": true
          },
          {
            "files": ["Sources/Acai/Constants.swift"],
            "from": "SDK_VERSION = \".*\"",
            "to": "SDK_VERSION = \"${nextRelease.version}\"",
            "results": [
              {
                "file": "Sources/Acai/Constants.swift",
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
      "assets": ["AcaiSwift.podspec", "Sources/Acai/Constants.swift", "CHANGELOG.md"],
      "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    ["@semantic-release/exec", {
      "publishCmd": "pod trunk push AcaiSwift.podspec --allow-warnings",
    }],
  ],
}
