# API Comparison Tool Plan

## Goal

Build a tool that compares the behavior of Plex API calls between `python-plexapi` and `perl-plexapi`. The tool should identify matching endpoints, differing parameter handling, response shape mismatches, and implementation gaps.

## Objectives

- Enumerate a shared set of Plex API endpoints exposed by both libraries.
- Execute matching calls against the same Plex server environment.
- Normalize responses and compare results.
- Record mismatches in a structured report.
- Provide a framework for ongoing API coverage regression testing.

## Key Components

### 1. Endpoint inventory

- Create a canonical endpoint list representing major API groups:
  - Server, Library, Video, Audio, Playlist, Collection, DownloadQueue, PlayQueue, Photo, Services, LiveTV, MyPlex, Client
- Each entry should include:
  - library method path / wrapper method name
  - request type (GET/POST/PUT/DELETE)
  - expected parameters
  - optional guid for equivalent python-plexapi call

### 2. Python runner

- A Python script that imports `python-plexapi` and invokes each target endpoint.
- Capture raw JSON output and metadata:
  - HTTP path / query
  - request parameters
  - response body
  - error conditions
- Use the same test Plex server credentials as the existing suite.

### 3. Perl runner

- A Perl CLI wrapper or lightweight JSON API around `perl-plexapi`.
- Example: `scripts/compare-perl-api.pl --endpoint download_queue.items --params '{"includeExtras":1}'`
- Output JSON for the same metadata fields as the Python runner.
- This can be implemented as a small command-line script using `WebService::Plex`.

### 4. Normalization layer

- Define rules to normalize both responses before comparison:
  - sort arrays where order is not significant
  - strip transient or server-specific fields (`id`, `updatedAt`, `uuid`, etc.)
  - normalize boolean/string forms and numeric types
- Use a shared normalization module or JSON comparison helper.

### 5. Comparison engine

- Compare Python and Perl results for each endpoint.
- Classify outcomes:
  - match: equivalent responses after normalization
  - partial match: same shape, different values
  - mismatch: structural differences
  - missing: endpoint implemented in one library but not the other
- Store results in a report format such as JSON and Markdown.

### 6. Reporting

- Generate human-readable output:
  - summary table of endpoint coverage
  - detailed diffs for failures
  - implementation gaps
- Optionally create an HTML report for easier review.

## Implementation Steps

1. Add a new inventory file, e.g. `tools/api-endpoint-list.yml`.
2. Build a minimal Perl CLI in `scripts/perl-api-runner.pl`.
3. Build a Python harness in `tools/python_api_compare.py`.
4. Implement JSON normalization and diffing.
5. Run the comparison against a configured Plex test server.
6. Add regression tests for the comparison tool itself.8. Document usage in `tools/api_compare/README.md` and link it from this plan.
## Environment and Dependencies

- Use the same Docker/Test server environment as the existing `perl-plexapi` suite.
- For the comparison tool, require:
  - Python 3.11+ or compatible
  - `python-plexapi`
  - JSON diff library such as `deepdiff` or a custom comparator
  - Perl with `WebService::Plex` available in the repository

## Next-phase enhancements

- Automate endpoint discovery from `python-plexapi` and `perl-plexapi` metadata.
- Add coverage metrics and gap analysis.
- Integrate the comparison report into CI.
- Support optional field-level equivalence rules for Plex-specific payloads.
