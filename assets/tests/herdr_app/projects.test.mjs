import assert from "node:assert/strict";
import { test } from "node:test";
import { openProject, projectLabel, projectRows } from "../../../dot_config/herdr-app/mods/pbogut-projects/projects.js";

const config = { root: "/projects", aliases: { "github.com": "gh", pbogut: "pb" } };
const path = "/projects/github.com/pbogut/project with spaces";
const projectRequest = (command) => {
  assert.ok(command[0].startsWith("pbogut-tabs.project@"));
  return JSON.parse(decodeURIComponent(command[0].slice("pbogut-tabs.project@".length)));
};

test("labels compact directory segments and retain the project name", () => {
  assert.equal(projectLabel(path, config), "gh󰿟pb󰿟project with spaces");
  assert.equal(projectLabel("/projects/github.com/pbogut", config), "gh󰿟pbogut");
  assert.equal(projectLabel("/elsewhere/my-pbogut/repo", config), "/elsewhere/my-pbogut/repo");
});

test("open spaces precede recent projects, deduplicated by local folder", () => {
  const spaces = [
    { id: "one", name: "My project", named: true, folder: `${path}/`, machine: null },
    { id: "remote", name: "Remote", named: true, folder: "/projects/remote", machine: "vps" },
  ];
  const rows = projectRows(spaces, [path, "/projects/new", "/projects/new/", "/projects/remote"], config);
  assert.deepEqual(rows.map((row) => row.label), ["My project", "Remote", "new", "remote"]);
  assert.deepEqual(openProject(rows[1], spaces), ["space.select", { id: "remote" }]);
});

test("search accepts aliases, full paths, custom names and multiple words", () => {
  assert.equal(projectRows([], [path], config, "GH spaces").length, 1);
  assert.equal(projectRows([], [path], config, "github.com pbogut").length, 1);
  assert.equal(projectRows([], [path], config, "missing").length, 0);
  assert.equal(projectRows([{ id: "one", name: "Custom", named: true, folder: path }], [], config, "custom spaces").length, 1);
  assert.equal(projectRows([{ id: "one", name: "Custom", named: true, folder: path }], [], config, "gh pb").length, 1);
});

test("opening rechecks live space state and never matches another machine's path", () => {
  const [row] = projectRows([], [path], config);
  assert.deepEqual(projectRequest(openProject(row, [{ id: "remote", folder: path, machine: "vps" }])),
    { label: "gh󰿟pb󰿟project with spaces", folder: path });
  assert.deepEqual(projectRequest(openProject(row, [{ id: "created-since-open", folder: `${path}/`, machine: null }])),
    { id: "created-since-open", label: "gh󰿟pb󰿟project with spaces", folder: `${path}/` });
  assert.equal(openProject({ ...row, id: "closed-space" }, []), null);
});
