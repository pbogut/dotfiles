const worktreePaths = (output) => output.split("\0")
  .filter((field) => field.startsWith("worktree ")).map((field) => field.slice(9));

export async function createDatedWorktree(row, name, exec, script) {
  if (!row?.folder || row.machine) throw new Error("Choose a local project with a .bare repository.");
  if (!name.trim()) throw new Error("Enter a branch name.");
  const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: row.folder });
  if (common.code !== 0) throw new Error(common.stderr.trim() || "Could not locate the repository.");
  const directory = common.stdout.trim();
  if (!directory.endsWith("/.bare")) throw new Error("Dated worktrees require a .bare repository.");
  const root = directory.slice(0, -6);
  if (/\s/.test(root)) throw new Error("The git-wt helper does not support whitespace in repository paths.");
  const list = async () => {
    const result = await exec("git", ["worktree", "list", "--porcelain", "-z"], { cwd: root });
    if (result.code !== 0) throw new Error(result.stderr.trim() || "Could not list worktrees.");
    return worktreePaths(result.stdout);
  };
  const before = await list();
  const result = await exec(script, [name.replace(/ /g, "-")], { cwd: root, timeout: 600_000 });
  if (result.code !== 0) throw new Error(result.stderr.trim() || "Could not create the worktree.");
  const folder = result.stdout.trim().split("\n").at(-1);
  // The existing helper prints its target path even when git wt fails.
  if (!folder || before.includes(folder) || !(await list()).includes(folder)) {
    throw new Error(result.stderr.trim() || "The script did not create a new worktree.");
  }
  return folder;
}
