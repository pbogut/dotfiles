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

test("marked projects and discovered projects are scoped to one machine and deduplicated", () => {
  const spaces = [
    { id: "one", name: "My project", named: true, folder: `${path}/`, machine: null },
    { id: "remote", name: "Remote", named: true, folder: "/projects/remote", machine: "vps" },
  ];
  const marked = { one: true, remote: true };
  const rows = projectRows(spaces, [path, "/projects/new", "/projects/new/", "/projects/remote"], config, "", null, marked);
  assert.deepEqual(rows.map((row) => row.label), ["My project", "new", "remote"]);
  const remote = projectRows(spaces, ["/projects/remote", path], config, "", "vps", marked);
  assert.deepEqual(remote.map((row) => row.label), ["Remote", "gh󰿟pb󰿟project with spaces"]);
  assert.deepEqual(projectRequest(openProject(remote[0], spaces, marked)),
    { id: "remote", folder: "/projects/remote", label: "Remote", machine: "vps" });
  assert.equal(projectRequest(openProject(remote[1], spaces, marked)).machine, "vps");
});

test("search accepts aliases, full paths, custom names and multiple words", () => {
  assert.equal(projectRows([], [path], config, "GH spaces").length, 1);
  assert.equal(projectRows([], [path], config, "github.com pbogut").length, 1);
  assert.equal(projectRows([], [path], config, "missing").length, 0);
  assert.equal(projectRows([{ id: "one", name: "Custom", named: true, folder: path }], [], config, "custom spaces", null, { one: true }).length, 1);
  assert.equal(projectRows([{ id: "one", name: "Custom", named: true, folder: path }], [], config, "gh pb", null, { one: true }).length, 1);
});

test("opening rechecks live space state and never matches another machine's path", () => {
  const [row] = projectRows([], [path], config);
  assert.deepEqual(projectRequest(openProject(row, [{ id: "remote", folder: path, machine: "vps" }])),
    { label: "gh󰿟pb󰿟project with spaces", folder: path, machine: null });
  assert.deepEqual(projectRequest(openProject(row, [{ id: "created-since-open", folder: `${path}/`, machine: null }], { "created-since-open": true })),
    { id: "created-since-open", label: "gh󰿟pb󰿟project with spaces", folder: `${path}/`, machine: null });
  assert.equal(openProject({ ...row, id: "closed-space" }, []), null);
});

test("ordinary spaces never appear as open projects or prevent opening a project in the same folder", () => {
  const spaces = [
    { id: "ordinary", name: "Scratch", named: true, folder: path },
    { id: "outside", name: "Notes", named: true, folder: "/notes" },
    { id: "remote", name: "Remote", named: true, folder: path, machine: "vps" },
  ];
  const [row] = projectRows(spaces, [path], config);
  assert.equal(row.id, undefined);
  assert.equal(row.label, "gh󰿟pb󰿟project with spaces");
  assert.deepEqual(projectRows(spaces, [], config), []);
  assert.deepEqual(projectRows(spaces, [path], config, "Scratch"), []);
  assert.equal(projectRows(spaces, [path], config, "", "vps")[0].id, undefined);
  assert.deepEqual(projectRequest(openProject(row, spaces)),
    { folder: path, label: row.label, machine: null });
  assert.equal(openProject({ ...row, id: "ordinary" }, spaces), null, "A stale row cannot promote an ordinary space");
  spaces.push({ id: "project", folder: path, name: "Project", named: true });
  const marked = { project: true, remote: true };
  const rows = projectRows(spaces, [path], config, "", null, marked);
  assert.deepEqual(rows.map(row => row.id), ["project"]);
  assert.equal(projectRequest(openProject(row, spaces, marked)).id, "project");
});
