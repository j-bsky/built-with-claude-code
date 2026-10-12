extends GdUnitTestSuite
## The engine/tools boundary, enforced by grepping source.
##
## res://engine/ must be runtime-safe: no @tool, no Editor* symbol, no
## res://addons/ path. Nothing in the type system expresses that, so — as
## with the grammar-expression guard in test_st_grammar.gd — reading the
## source as text is the only way to prove no violation can creep back in.
##
## Scanning rule: only the part of each line before an unquoted "#" is
## examined. These files are dense with docstrings that legitimately name
## EditorUndoRedoManager, EditorInterface and res://addons/, and a naive
## substring scan drowns in false positives.
##
## "Unquoted" is load-bearing and used not to be. `_code_of` cut at the first
## "#" anywhere on the line, so any line containing a "#" INSIDE a string
## literal was truncated there and the rest of it went unscanned — and engine/
## has several, including three GLSL templates opening `"""#version 450`. The
## helper is quote-aware now; see its own doc for what remains approximate.

const ENGINE_ROOT := "res://engine"
const CLI_ROOT := "res://cli"

## Raise as each addon lands so a silently-empty walk cannot pass — and
## LOWERED as a deliberate, announced act when engine code is deleted.
## Phase 2 (+sdf): 21   Phase 3 (+noise,elestruct): 61
## Phase 4 (+structura): 106   Phase 5 (+terrain,level): ~162
## GUI phase (+content_paths): 168   (+project_file): 169   (+rig): 174
## (+level): 178   (+level_import, M6): 179   (+drag_solve): 180
## (+grid: ig_grid_builder, ig_domain — M8a): 182
## M9a added terrain/height (+4 by completion); 2026-08-20 the dead island
## (terrain/generation 21 files + terrain_workspace.gd) was DELETED — 174
## .gd measured on deletion day, floor set just under it. (+fly_nav,
## 2026-08-21: 175; +heightfield_mesh, Part C same day: 176.)
const MIN_ENGINE_FILES := 172

## Sentinel files proving the walk descends into nested directories,
## not just the top level. Add one per addon as it lands.
const SENTINELS: Array[String] = [
	"res://engine/sdf/sdf_mesher.gd",
	"res://engine/noise/nf_workspace.gd",
	"res://engine/elestruct/elestruct_pipeline.gd",
	"res://engine/structura/stages/st_stage_wfc_volumes.gd",
	# Was generation/modifiers/terrain_modifier.gd (3 deep) until the island
	# deletion; height/ is terrain's surviving subtree. Depth >= 3 is still
	# proven by the structura/stages sentinel above.
	"res://engine/terrain/height/landform_blend.gd",
	"res://engine/level/symmetry.gd",
	"res://engine/rig/rig_ik.gd",
	"res://engine/grid/ig_grid_builder.gd",
	"res://engine/pipeline/pipeline_runner.gd",
]

## The one legitimate reason for engine code to name res://addons/: the
## export gate's list of prefixes it must REJECT. That string is data the
## engine refuses, not a path it reaches into — the exact opposite of what
## test_engine_and_cli_have_no_addon_paths is looking for. Keyed by both
## file and symbol so it cannot silently cover a real violation elsewhere
## in the file, and test_export_gate.gd independently proves the constant
## still does its job.
const ADDON_PATH_EXEMPT := {
	"res://engine/elestruct/elestruct_export.gd": "NON_PORTABLE_PREFIXES",
	# The rig exporter's private duplicate (the _mm precedent — engine/rig
	# imports neither engine/sdf nor engine/elestruct); same grounds.
	"res://engine/rig/rig_export.gd": "NON_PORTABLE_PREFIXES",
}

const EDITOR_NEEDLES: Array[String] = [
	"EditorPlugin", "EditorInterface", "EditorUndoRedoManager",
	"EditorFileSystem", "EditorFileDialog", "EditorSettings",
	"EditorScript", "EditorInspector", "EditorProperty",
	"EditorSelection", "EditorNode3DGizmo", "EditorResourcePreview",
]


## Every *.gd under `root`, recursively. Empty if the directory is absent.
func _walk(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := root.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_walk(path))
		elif entry.ends_with(".gd"):
			out.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return out


## The line with any trailing comment removed. See the scanning rule above.
##
## Quote-aware, because a naive `find("#")` truncates at the first hash even
## when it is inside a string literal — and engine/ genuinely contains those:
## `sdf_codegen.gd`'s `begins_with("#")`, `st_module_record.gd`'s `"%s@%d#%d…"`
## key format, and the three GLSL templates that open `"""#version 450`. Every
## one of those silently hid the rest of its line from all three invariants
## below. The header used to disclaim this as a known limitation that "does not
## occur here"; it did occur, so the limitation is removed rather than restated.
##
## Only `#` outside a string starts a comment. Escapes are honoured so a `\"`
## inside a literal does not appear to close it. Triple-quoted blocks are not
## tracked across lines — a `#` on a continuation line of a multi-line GLSL
## template can still truncate — so `_code_of` is a per-line approximation that
## is now correct for every single-line case.
func _code_of(line: String) -> String:
	return LineViews.code_of(line)


func _code_lines(path: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(path).split("\n")


# --- the invariants ----------------------------------------------------

func test_engine_has_no_tool_annotation() -> void:
	for path in _walk(ENGINE_ROOT):
		var n := 0
		for line in _code_lines(path):
			n += 1
			assert_str(_code_of(line).strip_edges()).override_failure_message(
				"%s:%d is still marked @tool — engine code must not run in the editor."
				% [path, n]).is_not_equal("@tool")


func test_engine_has_no_editor_symbols() -> void:
	# The explicit list documents what we expect; the RegEx catches any
	# Editor* class nobody thought to list.
	var catch_all := RegEx.create_from_string("\\bEditor[A-Z]\\w*")
	for path in _walk(ENGINE_ROOT):
		var n := 0
		for line in _code_lines(path):
			n += 1
			var code := _code_of(line)
			for needle in EDITOR_NEEDLES:
				assert_bool(code.contains(needle)).override_failure_message(
					"%s:%d uses an editor symbol (%s): %s"
					% [path, n, needle, code.strip_edges()]).is_false()
			var hit := catch_all.search(code)
			assert_bool(hit == null).override_failure_message(
				"%s:%d uses an unlisted editor symbol (%s): %s"
				% [path, n, "" if hit == null else hit.get_string(),
					code.strip_edges()]).is_true()


func test_engine_and_cli_have_no_addon_paths() -> void:
	# An engine that reaches back into res://addons/ cannot ship in a
	# binary that has no addons directory.
	var paths := _walk(ENGINE_ROOT)
	paths.append_array(_walk(CLI_ROOT))
	for path in paths:
		var n := 0
		for line in _code_lines(path):
			n += 1
			var code := _code_of(line)
			if ADDON_PATH_EXEMPT.has(path) and code.contains(ADDON_PATH_EXEMPT[path]):
				continue
			assert_bool(code.contains("res://addons/")).override_failure_message(
				"%s:%d reaches into res://addons/: %s"
				% [path, n, code.strip_edges()]).is_false()


func test_every_addon_path_exemption_is_still_live() -> void:
	# An exemption for a file or symbol that no longer exists is a hole
	# left permanently open. Each entry must still name a real line.
	for path in ADDON_PATH_EXEMPT:
		assert_bool(FileAccess.file_exists(path)).override_failure_message(
			"exempt file %s no longer exists — drop the entry." % path).is_true()
		var symbol: String = ADDON_PATH_EXEMPT[path]
		var live := false
		for line in _code_lines(path):
			var code := _code_of(line)
			if code.contains(symbol) and code.contains("res://addons/"):
				live = true
				break
		assert_bool(live).override_failure_message(
			"exemption %s -> %s no longer matches any line naming res://addons/; "
			% [path, symbol] + "drop the entry so the rule applies again.").is_true()


## This suite's ADDON_PATH_EXEMPT whitelists NON_PORTABLE_PREFIXES from the
## addon-path scan on the grounds that it is the gate's REJECT list — data the
## engine refuses rather than a path it reaches into. That exemption is only
## sound while the constant really is that list, so check it here rather than
## taking it on trust.
##
## Asserts on the constant, not on the file's text. It used to read the raw
## source and check it `contains("res://engine/")` — which any comment or
## docstring mentioning the path satisfies, in a 445-line file whose header
## discusses the portability invariant in prose. It also never mentioned
## res://cli/. test_export_gate.gd proves the behaviour; this proves the
## exemption above is still pointing at what it claims.
func test_the_exempted_constant_is_still_the_gates_reject_list() -> void:
	for prefixes: Array in [ElestructExport.NON_PORTABLE_PREFIXES,
			RigExport.NON_PORTABLE_PREFIXES]:
		for required in ["res://addons/", "res://engine/", "res://cli/"]:
			assert_bool(prefixes.has(required)).override_failure_message(
				"NON_PORTABLE_PREFIXES no longer rejects %s, so ADDON_PATH_EXEMPT "
				% required + "is whitelisting a constant that has stopped doing "
				+ "its job.").is_true()


# --- positive controls -------------------------------------------------
# Without these the suite passes trivially when _walk returns nothing,
# which is exactly what a broken walk or a renamed directory looks like.
#
# These run LAST on purpose: gdUnit aborts a suite at its first failure,
# so a control failing mid-file would mask every test after it. During
# the migration these are the expected-red ones.

func test_walker_actually_saw_the_engine() -> void:
	var found := _walk(ENGINE_ROOT)
	assert_int(found.size()).override_failure_message(
		"_walk(%s) found %d .gd files, expected at least %d. Either the "
		% [ENGINE_ROOT, found.size(), MIN_ENGINE_FILES]
		+ "migration has not reached this phase yet, or the walk is broken."
		).is_greater_equal(MIN_ENGINE_FILES)


## `test_engine_and_cli_have_no_addon_paths` scans `_walk(ENGINE_ROOT) +
## _walk(CLI_ROOT)`, but only the engine half had a positive control — and
## `_walk` returns empty for a directory that is not there, so relocating
## res://cli would have switched off the CLI half of the invariant while the
## engine's files kept the suite green.
##
## Asserted with a named sentinel rather than a file count. A count is what a
## reader reaches for first, but res://cli holds exactly 5 files, so any floor
## worth having sits on the current number with zero headroom and fails on an
## ordinary consolidation. The sentinel catches the same failure exactly — an
## empty or misdirected walk cannot contain cli_app.gd — and cannot false-fire.
func test_walker_actually_saw_the_cli() -> void:
	assert_bool(_walk(CLI_ROOT).has("res://cli/cli_app.gd")).override_failure_message(
		"_walk(%s) did not reach cli_app.gd — the CLI half of " % CLI_ROOT
		+ "test_engine_and_cli_have_no_addon_paths is scanning nothing and "
		+ "passing vacuously.").is_true()


func test_walker_descends_into_nested_directories() -> void:
	for sentinel in SENTINELS:
		assert_bool(_walk(ENGINE_ROOT).has(sentinel)).override_failure_message(
			"_walk did not reach %s — nested directories are not being "
			% sentinel + "scanned, so the invariants above prove nothing "
			+ "about them.").is_true()
