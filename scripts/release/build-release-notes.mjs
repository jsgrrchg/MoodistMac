#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function parseArgs(argv) {
  const options = {
    changelog: "CHANGELOG.md",
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith("--")) {
      throw new Error(`Unexpected argument: ${arg}`);
    }

    const key = arg.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`Missing value for ${arg}`);
    }

    options[key] = value;
    index += 1;
  }

  return options;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function inlineMarkdownToHtml(value) {
  return escapeHtml(value).replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
}

function extractSection(changelog, version) {
  const lines = changelog.split(/\r?\n/);
  const headingPattern = new RegExp(`^## \\[${escapeRegExp(version)}\\](?:\\s+[-\\u2013]\\s+(.+))?\\s*$`);
  const startIndex = lines.findIndex((line) => headingPattern.test(line));

  if (startIndex === -1) {
    throw new Error(`CHANGELOG.md does not contain a section for ${version}.`);
  }

  const heading = lines[startIndex];
  const date = heading.match(headingPattern)?.[1]?.trim() ?? "";
  let endIndex = lines.length;
  for (let index = startIndex + 1; index < lines.length; index += 1) {
    if (lines[index].startsWith("## ")) {
      endIndex = index;
      break;
    }
  }

  const body = lines.slice(startIndex + 1, endIndex).join("\n").trim();
  if (!body) {
    throw new Error(`CHANGELOG.md section for ${version} is empty.`);
  }

  return { body, date };
}

function sectionToHtml(markdown, version, tag, date) {
  const lines = markdown.split(/\r?\n/);
  const html = [
    "<!doctype html>",
    '<html lang="en">',
    "    <head>",
    '        <meta charset="utf-8" />',
    '        <meta name="viewport" content="width=device-width, initial-scale=1" />',
    `        <title>MoodistMac ${escapeHtml(version)} Release Notes</title>`,
    "    </head>",
    "    <body>",
    `        <h2>${escapeHtml(version)}${date ? ` (${escapeHtml(date)})` : ""}</h2>`,
  ];

  let listIsOpen = false;
  const closeList = () => {
    if (listIsOpen) {
      html.push("        </ul>");
      listIsOpen = false;
    }
  };

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }

    if (trimmed.startsWith("### ")) {
      closeList();
      html.push(`        <h3>${escapeHtml(trimmed.slice(4).trim())}</h3>`);
      continue;
    }

    if (trimmed.startsWith("- ")) {
      if (!listIsOpen) {
        html.push("        <ul>");
        listIsOpen = true;
      }
      html.push(`            <li>${inlineMarkdownToHtml(trimmed.slice(2).trim())}</li>`);
      continue;
    }

    closeList();
    html.push(`        <p>${inlineMarkdownToHtml(trimmed)}</p>`);
  }

  closeList();
  html.push("");
  html.push("        <p>");
  html.push(`            <a href="https://github.com/jsgrrchg/MoodistMac/releases/tag/${escapeHtml(tag)}">View this release on GitHub</a>`);
  html.push("        </p>");
  html.push("    </body>");
  html.push("</html>");

  return `${html.join("\n")}\n`;
}

const options = parseArgs(process.argv.slice(2));
const tag = options.tag;
const version = options.version ?? tag?.replace(/^v/, "");
const htmlOut = options["html-out"] ?? path.join("release-notes", `${tag}.html`);
const markdownOut = options["markdown-out"];

if (!tag || !version) {
  throw new Error("Both --tag and --version are required.");
}

const changelog = fs.readFileSync(options.changelog, "utf8");
const { body, date } = extractSection(changelog, version);
const html = sectionToHtml(body, version, tag, date);

fs.mkdirSync(path.dirname(htmlOut), { recursive: true });

if (fs.existsSync(htmlOut)) {
  const existing = fs.readFileSync(htmlOut, "utf8").trim();
  if (!existing) {
    throw new Error(`Existing release notes file is empty: ${htmlOut}`);
  }
} else {
  fs.writeFileSync(htmlOut, html);
}

if (markdownOut) {
  fs.mkdirSync(path.dirname(markdownOut), { recursive: true });
  fs.writeFileSync(markdownOut, `## ${version}${date ? ` - ${date}` : ""}\n\n${body}\n`);
}

console.log(htmlOut);
