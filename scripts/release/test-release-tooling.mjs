#!/usr/bin/env node
import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const releaseDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(releaseDir, "../..");
const updateAppcastScript = path.join(releaseDir, "update-appcast.mjs");
const buildReleaseNotesScript = path.join(releaseDir, "build-release-notes.mjs");
const validateReleaseTagScript = path.join(releaseDir, "validate-release-tag.sh");

const tests = [];

function test(name, fn) {
  tests.push({ name, fn });
}

function tempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "moodist-release-tests-"));
}

function writeFile(filePath, contents) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, contents);
}

function runNode(script, args, options = {}) {
  return execFileSync(process.execPath, [script, ...args], {
    cwd: repoRoot,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    ...options,
  });
}

function runShell(script, args, options = {}) {
  const result = spawnSync(script, args, {
    cwd: repoRoot,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    ...options,
  });

  if (result.status !== 0) {
    const output = `${result.stdout ?? ""}${result.stderr ?? ""}`.trim();
    throw new Error(output || `${script} exited with status ${result.status}`);
  }

  return result;
}

function expectFailure(fn, expectedMessage) {
  try {
    fn();
  } catch (error) {
    const message = String(error.stderr ?? error.message ?? error);
    assert.match(message, expectedMessage);
    return;
  }

  assert.fail("Expected command to fail.");
}

function appcastFixture() {
  return `<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>MoodistMac Updates</title>
        <description>MoodistMac ambient sound app updates.</description>
        <language>en</language>
        <item>
            <title>Version 1.0.5</title>
            <link>https://github.com/jsgrrchg/MoodistMac/releases/tag/v1.0.5</link>
            <sparkle:version>11</sparkle:version>
            <sparkle:shortVersionString>1.0.5</sparkle:shortVersionString>
            <sparkle:releaseNotesLink>https://raw.githubusercontent.com/jsgrrchg/MoodistMac/main/release-notes/v1.0.5.html</sparkle:releaseNotesLink>
            <sparkle:fullReleaseNotesLink>https://raw.githubusercontent.com/jsgrrchg/MoodistMac/main/release-notes/v1.0.5.html</sparkle:fullReleaseNotesLink>
            <pubDate>Mon, 27 Apr 2026 12:00:00 +0000</pubDate>
            <enclosure
                url="https://github.com/jsgrrchg/MoodistMac/releases/download/v1.0.5/MoodistMac.zip"
                sparkle:edSignature="existingSignature=="
                length="200218403"
                type="application/octet-stream"/>
        </item>
        <item>
            <title>Version 1.0.4</title>
            <sparkle:version>10</sparkle:version>
            <sparkle:shortVersionString>1.0.4</sparkle:shortVersionString>
            <enclosure
                url="https://github.com/jsgrrchg/MoodistMac/releases/download/v1.0.4/MoodistMac.zip"
                sparkle:edSignature="olderSignature=="
                length="200254418"
                type="application/octet-stream"/>
        </item>
    </channel>
</rss>
`;
}

function updateAppcast(appcastPath, overrides = {}) {
  const values = {
    tag: "v1.0.6",
    version: "1.0.6",
    build: "12",
    signature: "newSignature==",
    length: "123456",
    releaseNotesUrl: "https://raw.githubusercontent.com/jsgrrchg/MoodistMac/main/release-notes/v1.0.6.html",
    assetUrl: "https://github.com/jsgrrchg/MoodistMac/releases/download/v1.0.6/MoodistMac.zip",
    pubDate: "Thu, 28 May 2026 12:00:00 +0000",
    ...overrides,
  };

  return runNode(updateAppcastScript, [
    "--appcast",
    appcastPath,
    "--tag",
    values.tag,
    "--version",
    values.version,
    "--build",
    values.build,
    "--signature",
    values.signature,
    "--length",
    values.length,
    "--release-notes-url",
    values.releaseNotesUrl,
    "--asset-url",
    values.assetUrl,
    "--pub-date",
    values.pubDate,
  ]);
}

test("update-appcast inserts a new item first and preserves historical entries", () => {
  const dir = tempDir();
  const appcastPath = path.join(dir, "appcast.xml");
  writeFile(appcastPath, appcastFixture());

  updateAppcast(appcastPath);

  const updated = fs.readFileSync(appcastPath, "utf8");
  const insertedIndex = updated.indexOf("<sparkle:shortVersionString>1.0.6</sparkle:shortVersionString>");
  const existingIndex = updated.indexOf("<sparkle:shortVersionString>1.0.5</sparkle:shortVersionString>");
  const olderIndex = updated.indexOf("<sparkle:shortVersionString>1.0.4</sparkle:shortVersionString>");

  assert.ok(insertedIndex > -1, "new version should be inserted");
  assert.ok(existingIndex > -1, "latest historical version should remain");
  assert.ok(olderIndex > -1, "older historical version should remain");
  assert.ok(insertedIndex < existingIndex, "new version should appear before existing entries");
  assert.match(updated, /releases\/download\/v1\.0\.6\/MoodistMac\.zip/);
  assert.match(updated, /<sparkle:releaseNotesLink>https:\/\/raw\.githubusercontent\.com\/jsgrrchg\/MoodistMac\/main\/release-notes\/v1\.0\.6\.html<\/sparkle:releaseNotesLink>/);
  assert.match(updated, /<sparkle:fullReleaseNotesLink>https:\/\/raw\.githubusercontent\.com\/jsgrrchg\/MoodistMac\/main\/release-notes\/v1\.0\.6\.html<\/sparkle:fullReleaseNotesLink>/);
  assert.match(updated, /sparkle:edSignature="newSignature=="/);
  assert.match(updated, /length="123456"/);
  assert.match(updated, /releases\/download\/v1\.0\.5\/MoodistMac\.zip/);
  assert.match(updated, /sparkle:edSignature="existingSignature=="/);
  assert.match(updated, /releases\/download\/v1\.0\.4\/MoodistMac\.zip/);
  assert.match(updated, /sparkle:edSignature="olderSignature=="/);
});

test("update-appcast rejects duplicate versions", () => {
  const dir = tempDir();
  const appcastPath = path.join(dir, "appcast.xml");
  writeFile(appcastPath, appcastFixture());

  expectFailure(
    () => updateAppcast(appcastPath, { tag: "v1.0.5", version: "1.0.5", build: "12" }),
    /already contains version 1\.0\.5/
  );
});

test("update-appcast rejects non-incrementing Sparkle builds", () => {
  const dir = tempDir();
  const appcastPath = path.join(dir, "appcast.xml");
  writeFile(appcastPath, appcastFixture());

  expectFailure(() => updateAppcast(appcastPath, { build: "11" }), /must be greater than highest appcast build 11/);
});

test("build-release-notes extracts the requested changelog section as HTML and Markdown", () => {
  const dir = tempDir();
  const changelogPath = path.join(dir, "CHANGELOG.md");
  const htmlPath = path.join(dir, "release-notes", "v1.0.6.html");
  const markdownPath = path.join(dir, "release-notes.md");
  writeFile(
    changelogPath,
    `# Changelog

## [1.0.6] - 2026-05-28

### Fixed

- **Updates**: Preserve update metadata.
- Escape <unsafe> content safely.

## [1.0.5] - 2026-04-27

- Older entry.
`
  );

  runNode(buildReleaseNotesScript, [
    "--changelog",
    changelogPath,
    "--tag",
    "v1.0.6",
    "--version",
    "1.0.6",
    "--html-out",
    htmlPath,
    "--markdown-out",
    markdownPath,
  ]);

  const html = fs.readFileSync(htmlPath, "utf8");
  const markdown = fs.readFileSync(markdownPath, "utf8");

  assert.match(html, /^<!doctype html>/);
  assert.match(html, /<h2>1\.0\.6 \(2026-05-28\)<\/h2>/);
  assert.match(html, /<h3>Fixed<\/h3>/);
  assert.match(html, /<strong>Updates<\/strong>: Preserve update metadata\./);
  assert.match(html, /Escape &lt;unsafe&gt; content safely\./);
  assert.match(html, /releases\/tag\/v1\.0\.6/);
  assert.doesNotMatch(html, /Older entry/);
  assert.match(markdown, /^## 1\.0\.6 - 2026-05-28/);
});

test("build-release-notes fails when release notes are missing", () => {
  const dir = tempDir();
  const changelogPath = path.join(dir, "CHANGELOG.md");
  writeFile(
    changelogPath,
    `# Changelog

## [1.0.5] - 2026-04-27

- Older entry.
`
  );

  expectFailure(
    () =>
      runNode(buildReleaseNotesScript, [
        "--changelog",
        changelogPath,
        "--tag",
        "v1.0.6",
        "--version",
        "1.0.6",
        "--html-out",
        path.join(dir, "v1.0.6.html"),
      ]),
    /does not contain a section for 1\.0\.6/
  );
});

test("validate-release-tag requires tag and MARKETING_VERSION alignment", () => {
  const dir = tempDir();
  const changelogPath = path.join(dir, "CHANGELOG.md");
  const appcastPath = path.join(dir, "appcast.xml");
  writeFile(changelogPath, "# Changelog\n\n## [1.0.6] - 2026-05-28\n\n- Release entry.\n");
  writeFile(appcastPath, appcastFixture());

  runShell(validateReleaseTagScript, ["v1.0.6", "1.0.6", "12", changelogPath], {
    env: { ...process.env, APPCAST_PATH: appcastPath },
  });

  expectFailure(
    () =>
      runShell(validateReleaseTagScript, ["v1.0.6", "1.0.5", "12", changelogPath], {
        env: { ...process.env, APPCAST_PATH: appcastPath },
      }),
    /does not match MARKETING_VERSION/
  );
});

test("validate-release-tag rejects duplicate versions and stale build numbers", () => {
  const dir = tempDir();
  const changelogPath = path.join(dir, "CHANGELOG.md");
  const appcastPath = path.join(dir, "appcast.xml");
  writeFile(changelogPath, "# Changelog\n\n## [1.0.5] - 2026-04-27\n\n- Release entry.\n");
  writeFile(appcastPath, appcastFixture());

  expectFailure(
    () =>
      runShell(validateReleaseTagScript, ["v1.0.5", "1.0.5", "12", changelogPath], {
        env: { ...process.env, APPCAST_PATH: appcastPath },
      }),
    /already contains version 1\.0\.5/
  );

  writeFile(changelogPath, "# Changelog\n\n## [1.0.6] - 2026-05-28\n\n- Release entry.\n");
  expectFailure(
    () =>
      runShell(validateReleaseTagScript, ["v1.0.6", "1.0.6", "11", changelogPath], {
        env: { ...process.env, APPCAST_PATH: appcastPath },
      }),
    /must be greater than highest appcast build 11/
  );
});

test("project release deployment target remains macOS 15", () => {
  const projectPath = path.join(repoRoot, "Moodist.xcodeproj", "project.pbxproj");
  const project = fs.readFileSync(projectPath, "utf8");
  const deploymentTargets = [...project.matchAll(/MACOSX_DEPLOYMENT_TARGET = ([^;]+);/g)].map((match) => match[1].trim());

  assert.ok(deploymentTargets.length > 0, "expected at least one deployment target setting");
  assert.deepEqual([...new Set(deploymentTargets)], ["15.0"]);
});

let failed = 0;
for (const { name, fn } of tests) {
  try {
    fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    failed += 1;
    console.error(`FAIL ${name}`);
    console.error(error);
  }
}

if (failed > 0) {
  process.exitCode = 1;
}
