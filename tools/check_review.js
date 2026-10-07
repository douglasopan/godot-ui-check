// Optional, dependency-free generated-gallery validation. No browser is launched.
'use strict';
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const file = process.argv[2];
if (!file) throw new Error('Usage: node tools/check_review.js PATH_TO_GENERATED_HTML');
const html = fs.readFileSync(file, 'utf8');
const json = html.match(/<script id="report-data" type="application\/json">([\s\S]*?)<\/script>/);
if (!json) throw new Error('Missing report data');
const report = JSON.parse(json[1]);
if (!Array.isArray(report.pairs) || !report.pairs.length) throw new Error('Empty matrix');
const ids = new Set();
for (const pair of report.pairs) {
  if (ids.has(pair.id)) throw new Error('Duplicate case: ' + pair.id);
  ids.add(pair.id);
  for (const version of ['before', 'after']) {
    const bytes = Buffer.from(pair[version].split(',')[1], 'base64');
    if (bytes.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') throw new Error('Not a PNG');
    if (bytes.readUInt32BE(16) !== pair.width || bytes.readUInt32BE(20) !== pair.height) throw new Error('PNG dimensions mismatch');
  }
}
for (const match of html.matchAll(/<script(?: [^>]*)?>([\s\S]*?)<\/script>/g)) {
  if (!match[0].includes('application/json')) new vm.Script(match[1], {filename: path.basename(file)});
}
if (/<(?:script|link|img)[^>]+(?:src|href)=["']https?:/i.test(html)) throw new Error('External resource');
for (const id of ['locale', 'status', 'cases', 'split', 'before', 'after', 'download']) {
  if (!html.includes(`id="${id}"`)) throw new Error('Missing control ' + id);
}
console.log(JSON.stringify({check:'gallery syntax + data + dimensions + local resources',pairs:report.pairs.length,changed:report.changed,passed:true}));
